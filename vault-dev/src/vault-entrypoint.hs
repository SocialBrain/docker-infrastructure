import Control.Applicative
import Control.Concurrent (forkIO)
import Control.Exception
import Turtle
import Network.HTTP.Types
import Network.HTTP.Client (RequestBody(RequestBodyBS), HttpException(StatusCodeException))
import Network.Wreq
import Data.List
import Data.Traversable (for)
import Control.Lens hiding ((.=))
import Data.Aeson
import Data.Aeson.Lens
import qualified Data.Text.Encoding as DTE
import qualified Data.Text.Lazy.Encoding as DTLE
import qualified Data.Text as T
import System.Process
import qualified System.Process as P
import qualified Data.Text.Lazy as TL
import qualified Control.Foldl as Fold

main = do
  forkIO $
    waitForVaultStatus >>= \ case
      Unsealed      -> echo "confusingly, vault was already unsealed. leaving it alone"
      Sealed        -> unsealVault
      Uninitialized -> initializeAndUnsealVault

  (_, _, _, pid) <- createProcess $ (P.proc "/opt/vault/bin/vault" ["server", "-config=/etc/opt/vault/vault.hcl", "-log-level=debug"])
                                    { close_fds = True, create_group = True }

  catch (waitForProcess pid >>= exit)
        (\ (aex :: AsyncException) -> do
           case aex of
             UserInterrupt -> pure ()
             other -> echo $ "got asyncronous exception " <> (T.pack . show) aex
           terminateProcess pid
           waitForProcess pid
           exit $ ExitFailure 2)


data VaultStatus = Sealed | Unsealed | Uninitialized
waitForVaultStatus =
  let cs stat hdrs cookies | stat == status400 = Nothing
                           | statusIsSuccessful stat = Nothing
                           | otherwise = Just . toException $ StatusCodeException stat hdrs cookies in
  catch (do r <- getWith (defaults & checkStatus .~ Just cs) "http://127.0.0.1:8200/v1/sys/seal-status"
            case r ^? responseBody . key "sealed" . _Bool of
              Just True  -> echo "Vault is sealed"        >> return Sealed
              Just False -> echo "Vault is unsealed"      >> return Unsealed
              Nothing    -> echo "Vault is uninitialized" >> return Uninitialized)
        (\ (ex :: SomeException) -> do
             echo ("Vault unreachable: " <> (T.pack . show) ex)
             sleep 1
             waitForVaultStatus)

initializeAndUnsealVault = do
  r <- put "http://127.0.0.1:8200/v1/sys/init" $ object ["secret_shares" .= (1 :: Int), "secret_threshold" .= (1 :: Int)]
  case (,) <$> case r ^.. responseBody . key "keys" . values . _String of { [] -> Nothing; ks -> Just ks }
           <*> r ^? responseBody . key "root_token" . _String of
    Nothing -> do
      echo $ "failed to understand vault initialization response: " <> TL.toStrict (r ^. responseBody . to DTLE.decodeUtf8)
      exit ExitSuccess

    Just (keys :: [Text], rootToken :: Text) -> do

      waitForVaultStatus >>= \ case
        Unsealed      -> echo "confusingly, vault started out unsealed after initialization. pretending like this makes sense"
        Uninitialized -> echo "vault still uninitialized after initialization attempt" >> exit (ExitFailure 1)
        Sealed        -> echo "Vault initialized"

      echo $ "Storing token: " <> rootToken
      echo $ "Storing keys:"
      for keys $ echo . ("  " <>)

      mktree "/var/opt/vault/share"
      output "/var/opt/vault/share/root-token" (pure rootToken)
      output "/var/opt/vault/share/keys" $ foldl' (<|>) empty $ map pure keys

      unsealVault

      putWith (defaults & header "X-Vault-Token" .~ [DTE.encodeUtf8 rootToken]) "http://127.0.0.1:8200/v1/sys/audit/file" $
        object ["type" .= ("file" :: Text), "options" .= object ["path" .= ("/var/opt/vault/audit/vault-audit.log" :: Text)]]

      pure ()

unsealVault = do
  keys <- fold (input "/var/opt/vault/share/keys") Fold.list
  for keys $ \ key -> do
    echo $ "unsealing with key " <> key
    void $ put "http://127.0.0.1:8200/v1/sys/unseal" $ object ["key" .= key]
  waitForVaultStatus >>= \ case
    Unsealed      -> pure () -- waitForVaultStatus is noisy about the status
    Uninitialized -> echo "vault not initialized after unsealing?"
    Sealed        -> echo "unseal failed"
