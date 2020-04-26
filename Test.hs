#!/usr/bin/env nix-shell
#!nix-shell -i runhaskell -p "haskellPackages.ghcWithPackages(p: with p; [hspec process])" -p nix
{-# LANGUAGE OverloadedStrings #-}
import Test.Hspec
import System.Process
import qualified Data.Text as Text
import Data.Text (Text)
import Control.Monad.IO.Class (liftIO)
import Data.List (find)

-- | Utils function: run a command and returns its output.
processOutput p args = Text.strip . Text.pack <$> readProcess (Text.unpack p) (Text.unpack <$> args) ""

-- | Returns the path to the nixGLXXX binary.
nixGLBin version = (<>("/bin/"<>version)) <$> processOutput "nix-build" ["./", "-A", version]

-- | Returns the vendor string associated with a glxinfo wrapped by a nixGL.
getVendorString nixGL glxinfo = do
  output <- Text.lines <$> processOutput nixGL [glxinfo]
  pure $ Text.unpack <$> find ("OpenGL version string"`Text.isPrefixOf`) output

-- | Checks that a nixGL wrapper works with glxinfo 32 & 64 bits.
checkOpenGL_32_64 glxinfo32 glxinfo64 vendorName nixGLName = do
  nixGLBin <- runIO $ (<>("/bin/"<>nixGLName)) <$> processOutput "nix-build" ["./", "-A", nixGLName]

  it "32 bits" $ do
    Just vendorString <- getVendorString nixGLBin glxinfo32
    vendorString `shouldContain` vendorName

  it "64 bits" $ do
    Just vendorString <- getVendorString nixGLBin glxinfo64
    vendorString `shouldContain` vendorName

main = do
  glxinfo64 <- (<>"/bin/glxinfo") <$> processOutput "nix-build" ["<nixpkgs>", "-A", "glxinfo"]
  glxinfo32 <- (<>"/bin/glxinfo") <$> processOutput "nix-build" ["<nixpkgs>", "-A", "pkgsi686Linux.glxinfo"]

  let checkOpenGL = checkOpenGL_32_64 glxinfo32 glxinfo64

  hspec $ do
    describe "Mesa" $ do
      checkOpenGL "Mesa" "nixGLIntel"
    describe "Nvidia - Bumblebee" $ do
      checkOpenGL "NVIDIA" "nixGLNvidiaBumblebee"

    -- TODO: check Nvidia (I don't have this hardware)
    describe "Nvidia" $ do
      checkOpenGL "NVIDIA" "nixGLNvidia"

    -- TODO: check vulkan (I don't have vulkan compatible hardware)
