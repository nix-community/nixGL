#!/usr/bin/env nix-shell
#!nix-shell -i runhaskell -p "haskellPackages.ghcWithPackages(p: with p; [hspec process])" -p nix
{-# LANGUAGE OverloadedStrings #-}
import Test.Hspec
import System.Process
import qualified Data.Text as Text
import Data.Text (Text)
import Control.Monad.IO.Class (liftIO)
import Data.List (find)

currentChannel = "channel:nixos-19.03-small"

-- | Utils function: run a command and returns its output.
processOutput p args = Text.strip . Text.pack <$> readProcess (Text.unpack p) (Text.unpack <$> args) ""

-- | Returns the path to the nixGLXXX binary.
getNixGLBin version = (<>("/bin/"<>version)) <$> processOutput "nix-build" ["./", "-A", version, "--arg", "pkgs", "import (fetchTarball " <> currentChannel <> ")"]

-- | Returns the vendor string associated with a glxinfo wrapped by a nixGL.
getVendorString io = do
  output <- Text.lines <$> io
  pure $ Text.unpack <$> find ("OpenGL version string"`Text.isPrefixOf`) output

-- | Checks that a nixGL wrapper works with glxinfo 32 & 64 bits.
checkOpenGL_32_64 glxinfo32 glxinfo64 vendorName nixGLName = do
  beforeAll (getNixGLBin nixGLName) $ do
    it "32 bits" $ \nixGLBin -> do
      Just vendorString <- getVendorString (processOutput nixGLBin [glxinfo32, "-B"])
      vendorString `shouldContain` vendorName

    it "64 bits" $ \nixGLBin -> do
      Just vendorString <- getVendorString (processOutput nixGLBin [glxinfo64, "-B"])
      vendorString `shouldContain` vendorName

main = do
  -- nixos-18-03 is used so hopefully it will have a different libc
  -- than the one used in current nixOS system, so it will trigger the
  -- driver failure.
  glxinfo64 <- (<>"/bin/glxinfo") <$> processOutput "nix-build" [currentChannel, "-A", "glxinfo"]
  glxinfo32 <- (<>"/bin/glxinfo") <$> processOutput "nix-build" [currentChannel, "-A", "pkgsi686Linux.glxinfo"]

  let checkOpenGL = checkOpenGL_32_64 glxinfo32 glxinfo64

  hspec $ do
    describe "Must fail" $ do
      it "fails with unwrapped glxinfo64" $ do
        vendorString <- getVendorString (processOutput glxinfo64 [])
        vendorString `shouldBe` Nothing

      it "fails with unwrapped glxinfo32" $ do
        vendorString <- getVendorString (processOutput glxinfo32 [])
        vendorString `shouldBe` Nothing
    describe "Mesa" $ do
      checkOpenGL "Mesa" "nixGLIntel"
    describe "Nvidia - Bumblebee" $ do
      checkOpenGL "NVIDIA" "nixGLNvidiaBumblebee"

    -- TODO: check Nvidia (I don't have this hardware)
    describe "Nvidia" $ do
      checkOpenGL "NVIDIA" "nixGLNvidia"

    -- TODO: check vulkan (I don't have vulkan compatible hardware)
