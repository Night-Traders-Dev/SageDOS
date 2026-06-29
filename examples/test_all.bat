@ECHO OFF
CLS
VER
VOL
DATE
TIME
ECHO Creating test directory...
MD TESTDIR
CD TESTDIR
ECHO Directory changed. Current path:
CD
ECHO Hello > file1.txt
ECHO World >> file1.txt
TYPE file1.txt
COPY file1.txt file2.txt
DIR
REN file1.txt file3.txt
DIR
DEL file3.txt
DIR
DEL file2.txt
CD ..
RD TESTDIR
SET MYVAR=Success
ECHO Environment variable MYVAR is %MYVAR%
PROMPT [TestPrompt]$G
TITLE Test Window Title
COLOR 0A
VERIFY ON
REM This is a comment
PAUSE
EXIT
