module Main
  ( main
  )
where

import qualified Data.Map                      as M
import           Debug.Trace

main :: IO ()
main = return ()

type InputData = [Int]
type OutputData = [Int]
type Program = M.Map Int Int -- [0] 231

type RunTime = (InputData, Program, OutputData)

type CursorPosition = Int
type RelativeBase = Int

data Op = Add | Multiply | Input | Output |JumpIfTrue | JumpIfFalse | LessThen | Equals | RelBase | Halt deriving (Eq, Show)
data ArgMode = Position | Immediate | Relative deriving (Eq, Show)

runVM :: InputData -> [Int] -> ([Int], [Int])
runVM input cmd = (code, out)
 where
  program               = M.fromList $ zip [0 ..] cmd
  (_, codeWithIds, out) = exec 0 0 (input, program, [])
  code                  = map snd (M.toList codeWithIds)

exec :: CursorPosition -> RelativeBase -> RunTime -> RunTime
exec curPos relBase (inpData, program, outData) =
  trace
      (  "\n"
      ++ show inpData
      ++ "\n"
      ++ show (map snd (M.toList program))
      ++ "\n"
      ++ show outData
      ++ "\n"
      )
    $ runCmd cmd (inpData, program, outData)
 where
  -- utils 
  normalizeOpcode [a, b, c, d, e] = [a, b, c, d, e]
  normalizeOpcode n               = normalizeOpcode $ '0' : n

  makeCmd "01" = Add
  makeCmd "02" = Multiply
  makeCmd "03" = Input
  makeCmd "04" = Output
  makeCmd "05" = JumpIfTrue
  makeCmd "06" = JumpIfFalse
  makeCmd "07" = LessThen
  makeCmd "08" = Equals
  makeCmd "09" = RelBase
  makeCmd "99" = Halt
  makeCmd n    = error ("wrong op type: " ++ n)

  getMode '0' = Position
  getMode '1' = Immediate
  getMode '2' = Relative

  getVal id = f $ M.lookup id program
   where
    f (Just n) = n
    f Nothing  = 0 --error ("wrong id: " ++ show id)

  getValByMode arg Position  = getVal $ getVal arg
  getValByMode arg Immediate = getVal arg
  getValByMode arg Relative  = getVal (getVal arg + relBase)


  -- parse conf
  [cmdA, cmdB] = drop 3 opcode
  opcode       = normalizeOpcode . show $ getVal curPos

  cmd          = makeCmd [cmdA, cmdB]
  arg3Mode     = getMode $ head opcode
  arg2Mode     = getMode $ opcode !! 1
  arg1Mode     = getMode $ opcode !! 2

--   arg1         = getValByMode (curPos + 1) arg1Mode
--   arg2         = getValByMode (curPos + 2) arg2Mode
--   arg3         = getValByMode (curPos + 3) Immediate

  getNewCurPos Add      cur new = if new == cur then cur else cur + 4
  getNewCurPos Multiply cur new = if new == cur then cur else cur + 4
  getNewCurPos Input    cur new = if new == cur then cur else cur + 2
  getNewCurPos LessThen cur new = if new == cur then cur else cur + 4
  getNewCurPos Equals   cur new = if new == cur then cur else cur + 4

  applyArg1AndArg2AndSaveAtArg3 (inpData, program, outData) f = exec
    newCurPos
    relBase
    (inpData, newProgram, outData)
   where
    newCurPos    = trace (show cmd) $ getNewCurPos cmd curPos addResultPos
    newProgram   = M.insert addResultPos newVal program
    newVal       = f arg1 arg2
    addResultPos = arg3
    arg1         = getValByMode (curPos + 1) arg1Mode
    arg2         = getValByMode (curPos + 2) arg2Mode
    arg3         = getValByMode (curPos + 3) Immediate

  applyIfArg1AndArg2AndSaveAtArg3 (inpData, program, outData) f = exec
    newCurPos
    relBase
    (inpData, newProgram, outData)
   where
    newCurPos  = getNewCurPos cmd curPos newValPos
    newVal     = if f arg1 arg2 then 1 else 0
    newValPos  = arg3
    newProgram = M.insert newValPos newVal program
    arg1       = getValByMode (curPos + 1) arg1Mode
    arg2       = getValByMode (curPos + 2) arg2Mode
    arg3       = getValByMode (curPos + 3) Immediate

  -- cmd cases
  runCmd :: Op -> RunTime -> RunTime
  runCmd Add runTime = applyArg1AndArg2AndSaveAtArg3 runTime (+)
  runCmd Multiply runTime = applyArg1AndArg2AndSaveAtArg3 runTime (*)
  runCmd Input (inpData, program, outData) = exec
    newCurPos
    relBase
    (newInpData, newProgram, outData)
   where
    newCurPos                 = getNewCurPos Input curPos valToInputPos
    valToInputPos             = arg1
    (valToInput : newInpData) = inpData
    newProgram                = M.insert valToInputPos valToInput program
    arg1                      = getValByMode (curPos + 1) Immediate

  runCmd Output (inpData, program, outData) = exec
    newCurPos
    relBase
    (inpData, program, newOutData)
   where
    newCurPos  = curPos + 2
    newOutData = outData ++ [arg1]
    arg1       = getValByMode (curPos + 1) arg1Mode

  runCmd JumpIfTrue runTime = if arg1 /= 0
    then exec arg2 relBase runTime
    else exec (curPos + 3) relBase runTime
   where
    arg1 = getValByMode (curPos + 1) arg1Mode
    arg2 = getValByMode (curPos + 2) arg2Mode


  runCmd JumpIfFalse runTime = if arg1 == 0
    then exec arg2 relBase runTime
    else exec (curPos + 3) relBase runTime
   where
    arg1 = getValByMode (curPos + 1) arg1Mode
    arg2 = getValByMode (curPos + 2) arg2Mode

  runCmd LessThen runTime = applyIfArg1AndArg2AndSaveAtArg3 runTime (<)
  runCmd Equals   runTime = applyIfArg1AndArg2AndSaveAtArg3 runTime (==)
  runCmd RelBase  runTime = exec newCurPos newRelBase runTime
   where
    newCurPos  = curPos + 2
    newRelBase = relBase + arg1
    arg1       = getValByMode (curPos + 1) arg1Mode

  runCmd Halt runTime = runTime


code :: [Int]
code =
  [ 1102
  , 34463338
  , 34463338
  , 63
  , 1007
  , 63
  , 34463338
  , 63
  , 1005
  , 63
  , 53
  , 1102
  , 3
  , 1
  , 1000
  , 109
  , 988
  , 209
  , 12
  , 9
  , 1000
  , 209
  , 6
  , 209
  , 3
  , 203
  , 0
  , 1008
  , 1000
  , 1
  , 63
  , 1005
  , 63
  , 65
  , 1008
  , 1000
  , 2
  , 63
  , 1005
  , 63
  , 904
  , 1008
  , 1000
  , 0
  , 63
  , 1005
  , 63
  , 58
  , 4
  , 25
  , 104
  , 0
  , 99
  , 4
  , 0
  , 104
  , 0
  , 99
  , 4
  , 17
  , 104
  , 0
  , 99
  , 0
  , 0
  , 1102
  , 1
  , 30
  , 1010
  , 1102
  , 1
  , 38
  , 1008
  , 1102
  , 1
  , 0
  , 1020
  , 1102
  , 22
  , 1
  , 1007
  , 1102
  , 26
  , 1
  , 1015
  , 1102
  , 31
  , 1
  , 1013
  , 1102
  , 1
  , 27
  , 1014
  , 1101
  , 0
  , 23
  , 1012
  , 1101
  , 0
  , 37
  , 1006
  , 1102
  , 735
  , 1
  , 1028
  , 1102
  , 1
  , 24
  , 1009
  , 1102
  , 1
  , 28
  , 1019
  , 1102
  , 20
  , 1
  , 1017
  , 1101
  , 34
  , 0
  , 1001
  , 1101
  , 259
  , 0
  , 1026
  , 1101
  , 0
  , 33
  , 1018
  , 1102
  , 1
  , 901
  , 1024
  , 1101
  , 21
  , 0
  , 1016
  , 1101
  , 36
  , 0
  , 1011
  , 1102
  , 730
  , 1
  , 1029
  , 1101
  , 1
  , 0
  , 1021
  , 1102
  , 1
  , 509
  , 1022
  , 1102
  , 39
  , 1
  , 1005
  , 1101
  , 35
  , 0
  , 1000
  , 1102
  , 1
  , 506
  , 1023
  , 1101
  , 0
  , 892
  , 1025
  , 1101
  , 256
  , 0
  , 1027
  , 1101
  , 25
  , 0
  , 1002
  , 1102
  , 1
  , 29
  , 1004
  , 1102
  , 32
  , 1
  , 1003
  , 109
  , 9
  , 1202
  , -3
  , 1
  , 63
  , 1008
  , 63
  , 39
  , 63
  , 1005
  , 63
  , 205
  , 1001
  , 64
  , 1
  , 64
  , 1106
  , 0
  , 207
  , 4
  , 187
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -2
  , 1208
  , -4
  , 35
  , 63
  , 1005
  , 63
  , 227
  , 1001
  , 64
  , 1
  , 64
  , 1105
  , 1
  , 229
  , 4
  , 213
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 5
  , 1206
  , 8
  , 243
  , 4
  , 235
  , 1106
  , 0
  , 247
  , 1001
  , 64
  , 1
  , 64
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 14
  , 2106
  , 0
  , 1
  , 1105
  , 1
  , 265
  , 4
  , 253
  , 1001
  , 64
  , 1
  , 64
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -25
  , 1201
  , 4
  , 0
  , 63
  , 1008
  , 63
  , 40
  , 63
  , 1005
  , 63
  , 285
  , 1106
  , 0
  , 291
  , 4
  , 271
  , 1001
  , 64
  , 1
  , 64
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 14
  , 2107
  , 37
  , -7
  , 63
  , 1005
  , 63
  , 313
  , 4
  , 297
  , 1001
  , 64
  , 1
  , 64
  , 1106
  , 0
  , 313
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -7
  , 21101
  , 40
  , 0
  , 5
  , 1008
  , 1013
  , 37
  , 63
  , 1005
  , 63
  , 333
  , 1105
  , 1
  , 339
  , 4
  , 319
  , 1001
  , 64
  , 1
  , 64
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -7
  , 1207
  , 0
  , 33
  , 63
  , 1005
  , 63
  , 355
  , 1106
  , 0
  , 361
  , 4
  , 345
  , 1001
  , 64
  , 1
  , 64
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 7
  , 21102
  , 41
  , 1
  , 9
  , 1008
  , 1017
  , 41
  , 63
  , 1005
  , 63
  , 387
  , 4
  , 367
  , 1001
  , 64
  , 1
  , 64
  , 1106
  , 0
  , 387
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -1
  , 21102
  , 42
  , 1
  , 10
  , 1008
  , 1017
  , 43
  , 63
  , 1005
  , 63
  , 411
  , 1001
  , 64
  , 1
  , 64
  , 1106
  , 0
  , 413
  , 4
  , 393
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -5
  , 21101
  , 43
  , 0
  , 8
  , 1008
  , 1010
  , 43
  , 63
  , 1005
  , 63
  , 435
  , 4
  , 419
  , 1106
  , 0
  , 439
  , 1001
  , 64
  , 1
  , 64
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 16
  , 1206
  , 3
  , 455
  , 1001
  , 64
  , 1
  , 64
  , 1106
  , 0
  , 457
  , 4
  , 445
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -8
  , 21107
  , 44
  , 45
  , 7
  , 1005
  , 1017
  , 479
  , 4
  , 463
  , 1001
  , 64
  , 1
  , 64
  , 1106
  , 0
  , 479
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 6
  , 1205
  , 5
  , 497
  , 4
  , 485
  , 1001
  , 64
  , 1
  , 64
  , 1106
  , 0
  , 497
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 1
  , 2105
  , 1
  , 6
  , 1105
  , 1
  , 515
  , 4
  , 503
  , 1001
  , 64
  , 1
  , 64
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -10
  , 2108
  , 36
  , -1
  , 63
  , 1005
  , 63
  , 535
  , 1001
  , 64
  , 1
  , 64
  , 1105
  , 1
  , 537
  , 4
  , 521
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -12
  , 2101
  , 0
  , 6
  , 63
  , 1008
  , 63
  , 32
  , 63
  , 1005
  , 63
  , 561
  , 1001
  , 64
  , 1
  , 64
  , 1105
  , 1
  , 563
  , 4
  , 543
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 25
  , 21108
  , 45
  , 46
  , -2
  , 1005
  , 1018
  , 583
  , 1001
  , 64
  , 1
  , 64
  , 1105
  , 1
  , 585
  , 4
  , 569
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -23
  , 2108
  , 34
  , 4
  , 63
  , 1005
  , 63
  , 607
  , 4
  , 591
  , 1001
  , 64
  , 1
  , 64
  , 1106
  , 0
  , 607
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 3
  , 1202
  , 7
  , 1
  , 63
  , 1008
  , 63
  , 22
  , 63
  , 1005
  , 63
  , 633
  , 4
  , 613
  , 1001
  , 64
  , 1
  , 64
  , 1106
  , 0
  , 633
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 12
  , 21108
  , 46
  , 46
  , 3
  , 1005
  , 1015
  , 651
  , 4
  , 639
  , 1106
  , 0
  , 655
  , 1001
  , 64
  , 1
  , 64
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -5
  , 2102
  , 1
  , -1
  , 63
  , 1008
  , 63
  , 35
  , 63
  , 1005
  , 63
  , 679
  , 1001
  , 64
  , 1
  , 64
  , 1105
  , 1
  , 681
  , 4
  , 661
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 13
  , 21107
  , 47
  , 46
  , -7
  , 1005
  , 1013
  , 701
  , 1001
  , 64
  , 1
  , 64
  , 1105
  , 1
  , 703
  , 4
  , 687
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -2
  , 1205
  , 2
  , 715
  , 1106
  , 0
  , 721
  , 4
  , 709
  , 1001
  , 64
  , 1
  , 64
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 17
  , 2106
  , 0
  , -7
  , 4
  , 727
  , 1105
  , 1
  , 739
  , 1001
  , 64
  , 1
  , 64
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -23
  , 2107
  , 38
  , -6
  , 63
  , 1005
  , 63
  , 759
  , 1001
  , 64
  , 1
  , 64
  , 1106
  , 0
  , 761
  , 4
  , 745
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -3
  , 1207
  , -4
  , 40
  , 63
  , 1005
  , 63
  , 779
  , 4
  , 767
  , 1105
  , 1
  , 783
  , 1001
  , 64
  , 1
  , 64
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -8
  , 2101
  , 0
  , -1
  , 63
  , 1008
  , 63
  , 35
  , 63
  , 1005
  , 63
  , 809
  , 4
  , 789
  , 1001
  , 64
  , 1
  , 64
  , 1105
  , 1
  , 809
  , 1002
  , 64
  , 2
  , 64
  , 109
  , -6
  , 2102
  , 1
  , 8
  , 63
  , 1008
  , 63
  , 32
  , 63
  , 1005
  , 63
  , 835
  , 4
  , 815
  , 1001
  , 64
  , 1
  , 64
  , 1106
  , 0
  , 835
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 6
  , 1201
  , 5
  , 0
  , 63
  , 1008
  , 63
  , 37
  , 63
  , 1005
  , 63
  , 857
  , 4
  , 841
  , 1106
  , 0
  , 861
  , 1001
  , 64
  , 1
  , 64
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 2
  , 1208
  , 0
  , 32
  , 63
  , 1005
  , 63
  , 883
  , 4
  , 867
  , 1001
  , 64
  , 1
  , 64
  , 1106
  , 0
  , 883
  , 1002
  , 64
  , 2
  , 64
  , 109
  , 23
  , 2105
  , 1
  , -2
  , 4
  , 889
  , 1001
  , 64
  , 1
  , 64
  , 1106
  , 0
  , 901
  , 4
  , 64
  , 99
  , 21102
  , 27
  , 1
  , 1
  , 21101
  , 0
  , 915
  , 0
  , 1106
  , 0
  , 922
  , 21201
  , 1
  , 55337
  , 1
  , 204
  , 1
  , 99
  , 109
  , 3
  , 1207
  , -2
  , 3
  , 63
  , 1005
  , 63
  , 964
  , 21201
  , -2
  , -1
  , 1
  , 21101
  , 0
  , 942
  , 0
  , 1105
  , 1
  , 922
  , 21202
  , 1
  , 1
  , -1
  , 21201
  , -2
  , -3
  , 1
  , 21102
  , 957
  , 1
  , 0
  , 1105
  , 1
  , 922
  , 22201
  , 1
  , -1
  , -2
  , 1106
  , 0
  , 968
  , 21201
  , -2
  , 0
  , -2
  , 109
  , -3
  , 2105
  , 1
  , 0
  ]
