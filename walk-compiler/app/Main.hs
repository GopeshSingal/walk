module Main where

import System.Environment (getArgs)

main :: IO ()
main = do
    args <- getArgs
    putStrLn "Welcome to the Walk compiler!"
    putStrLn $ "The following arguments were passed: " ++ show args
