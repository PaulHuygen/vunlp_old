m4_include(inst.m4)m4_dnl
\documentclass[twoside]{artikel3}
\newcommand{\thedoctitle}{m4_doctitle}
\newcommand{\theauthor}{m4_author}
\newcommand{\thesubject}{m4_subject}
\pagestyle{headings}
\usepackage{pdfswitch}
\usepackage{figlatex}
\usepackage{makeidx}
\newcommand{\UTF}{\textsc{utf}}
\newcommand{\XML}{\textsc{xml}}
\renewcommand{\indexname}{General index}
\title{\thedoctitle}
\author{\theauthor}
m4_include(texinclusions.m4)m4_dnl
\begin{document}
\maketitle
\begin{abstract}
This document creates and documents a service to process text-files
with the Alpino dependency-parser on the Lisa supercomputer.
\end{abstract}
\tableofcontents

\section{Introduction}
\label{sec:introduction}

\begin{itemize}
\item Need for Natural Language Processing (\textsc{nlp}) tools that are resource-intensive.
\item Unleash the power of our supercomputer for this.
\item Have nodes of the supercomputer to process documents in parallel with the same \textsc{nlp} parser.
\item Scale advantage.
\item Users from the University campus copy their documents into an
  in-tray and find after some time the processed version of the
  document in an out-tray.
\end{itemize}

\subsection{How does it work?}
\label{sec:how}

\subsubsection{Trays}
\label{sec:trays}

\begin{itemize}
\item In-tray collects files that have been submitted by users.
\item When a parser processes a file it moves the file to a process-tray.
\item When the parser finishes a parse it writes the result as a file in an out-tray and removes the file from the process-tray.
\item When the processing of the file takes too long, the file is
  moved from the processing-tray to a time-out tray.
\item If the parser has been killed before it has finished its job, the file is replaced from the process-tray into the in-tray.
\item Users collect the results from the out-tray.
\end{itemize}

\subsubsection{Process manager}
\label{sec:process-manager}

\begin{itemize}
\item Starts periodically (cron job).
\item Checks whether users have submitted files.
\item Submits a sufficient amount of parser jobs that process the input-files.
\item Checks whether parser jobs have been killed and moves unprocessed files from the process-tray back into the in-tray.
\item Checks synchronisation mechanism (cf. section~\ref{sec:synchronisation})
\end{itemize}

\subsubsection{Parse jobs}
\label{sec:parsejobs}

\begin{itemize}
\item Submitted by the process manager.
\item Each job runs on a single node of the supercomputer.
\item Use the cores of the node to process multiple documents simultaneously.
\item How to pass arguments for the parser? Two possibilities: 1) in an extra file with a name that is related to the first file; 2) on the first line of the input file.
\end{itemize}

\subsubsection{Synchronisation}
\label{sec:synchronisation_description}

\begin{itemize}
\item Prevent that two processes select the same input file for processing.
\item File selection must be atomic action.
\item Creation of a directory is atomic action, therefore generate a semaphore mechanism that works by creating and removing a block-directory.
\item Problem: Possibility that a process is killed before it would remove the block-directory that it has created.
\item Solution: Process-manager kills old block-directories.
\item Problem: Possibility that process copies an input file that is still in status nascendi.
\item Two possible solutions: 1) user submits the file and then  second file with e similar name. If the second file is present, the copying of the first file must have been completed; 2) Process a file only when it is older than e.g. one minute.
\end{itemize}

\section{Implementation}
\label{sec:implementation}

\subsection{Directory structure}
\label{sec:directorystructure}

We have directories for the following:

\begin{description}
\item[trays:] Each of the ``trays'' is a directory.
\item[bin:] A directory for binaries etc.
\end{description}

@d parameters in Makefile @{@%
DIRS = m4_aindir \
       m4_aprocdir \
       m4_aoutdir \
       m4_atooodir \
       m4_abindir

@| @}

@d define variables for filenames @{@%
INBAK=m4_aindir
UITBAK=m4_aoutdir
PROCBAK=m4_aprocdir
TOOOBAK=m4_atooodir
PROJROOT=m4_aprojroot
cd \$PROJROOT
@| INBAK UITBAK PROCBAK @}


\subsection{Parser}
\label{sec:parser}

This document implements a service for the Alpino parser (\url{http://www.let.rug.nl/vannoord/alp/Alpino/}). So we obviously need this thing.

@d parameters in Makefile @{@%
ALPINO_TARBALL = m4_alpinotarball
ALPINO_URL = m4_alpino_url
LOCAL_ALPINO = m4_abindir/m4_alpinotarball
@| @}

@d expliciete make regels @{@%
\$(LOCAL_ALPINO) : 
	cd m4_abindir && wget m4_alpino_url

@| @}

\subsection{Synchronisation mechanism}
\label{sec:synchronisation}

Make a mechanism that ensures that only a single process can execute
some functions at a time. For instance, if a process selects a file to
be processed next, it selects a file name from a directory-listing and
then removes the selected file from the directory. The two steps form
a ``critical code section'' and only a single process at a time should
be allowed to execute this section. Therefore, generate the functions \verb|passeer| and
\verb|veilig| (cf. E.W.~Dijkstra). When a process completes
\verb|passeer|, no other processes can complete \verb|passeer| until
the first process executes \verb|veilig|.

Function \verb|passeer| tries repeatedly to create a \emph{lock
  directory}, until it succeeds and function \verb|veilig| removes the
lock directory.


Sometimes de-synchonisation is good, to prevent that all processes are
waiting at the same time for the same event. Therefore, now and then a
process should wait a random amount of time. We don't need to use
sleep, because the cores have no other work to do.

@d synchronisation functions @{@%
waitabit()
{ ( RR=\$RANDOM
    while
      [ \$RR -gt 0 ]
    do
    RR=\$((RR - 1))
    done
  )
  
}

@| @}


@d synchronisation functions @{@%
export LOCKDIR=m4_lockdir

function passeer () {
 while ! (mkdir \$LOCKDIR 2> /dev/null)
 do
@%  sleep 1
   waitabit
 done
}

function veilig () {
  rmdir "\$LOCKDIR"
}

@| passeer veilig LOCKDIR @}

The processes that execute these functions can crash and they are
killed when the time alotted to them has been used up. Thus it
is possible that a process that executed \verb|passeer| is not able to
execute \verb|veilig|. As a result, all other processes would come to a
halt. Therefore, check the age of the lock directory periodically and
remove the directory when it is older than, say, two minutes (executing critical code
sections ought to take only a very short amount of time).

@d synchronisation functions  @{@%
@%export LOCKDIR=m4_lockdir
find \$LOCKDIR -amin m4_locktimeout -print 2>/dev/null | xargs rm -rf
@| @}

The synchronisation mechanism can be used to have parallel processed
update the same counter. 

@d increment filecontent @{@%
passeer
NUM=`cat @1`
echo \$((NUM + 1 )) > @1
veilig
@| @}

@d decrement filecontent @{@%
passeer
NUM=`cat @1`
echo \$((NUM - 1 )) > @1
veilig
@| @}

We will need a mechanism to find out whether a certain operation has
taken place within a certain past time period. We use the timestamp of
a file for that. When the operation to be monitored is executed, the
file is touched. The following macro checks such a file. It has the
following three arguments: 1) filename; 2) time-out period; 3)
result. The result parameter will become true when the file didn't
exist or when it had not been touched during the time-out period. In
those cases the macro touches the file.

@d check whether update is necessary  @{@%
@< write log @(now: `date +%s`@) @>
arg=@1
stamp=`date -r @1 +%s`
@< write log @($arg: $stamp@) @>
passeer
if [ ! -e @1 ]
then
  @3=true
elif [ \$((`date +%s` - `date -r @1 +%s`)) -gt @2 ]
then
  @3=true
else
  @3=false
fi
if \$@3
then
  echo `date` > @1
fi
veilig
if \$@3
then
  @< write log @(yes, update@) @>
else
  @< write log @(no, no update@) @>
fi
@| @}




\subsection{Temporary files}
\label{sec:tempfiles}

We will often use temporary files. Generate a filename for a temporary
file that will be removed after use.

@d create name for tempfile @{@%
tmpfil=`mktemp --tmpdir tmp.XXXXXXX`
rm -rf \$tmpfil
@| tmpfil @}


\subsection{Log mechanism}
\label{sec:log}

Write to a log file if logging is set to true.

@d init logfile @{@%
LOGGING=m4_logging
LOGFIL=m4_logfile
PROGNAM=@1
@| LOGGING LOGFIL @}

@d write log @{@%
if LOGGING=true
then
  echo `date`";" \$PROGNAM":" @1 >>\$LOGFIL
fi
@| @}





\subsection{Manage the jobs}
\label{sec:jobtrack}

When we have received files to be parsed we have to submit the proper
amount of parse jobs. To determine whether new jobs have to be
submitted we have to know the number of waiting and running
jobs. Unfortunately it is too costly to often request a list of
running jobs. Therefore we will make a bookkeeping. File
\verb|m4_jobcountfile| contains a list of the running and waiting
jobs.

@d define variables for filenames @{@%
JOBCOUNTFILE=m4_jobcountfile
@| JOBCOUNTFILE @}


It is updated as follows:

\begin{itemize}
\item When a job is submitted, a line containing the job-id, the word
  ``wait'' and a timestamp is added to the file.
\item A job that starts, replaces in the line with its job-id the word
  ``waiting'' by running and replaces the timestamp.
\item A job that ends regularly removes the line with its job-id.
\item A job that ends leaves a log message. The filename consists of a 
  concatenation of the jobname, a dot, the character ``o'' and the
  job-id. At a regular basis the existence of such files is checked
  and \verb|\$JOBCOUNTFILE| updated. 
\end{itemize}

@%Initialize things:
@%
@%@d initialize job counting @{@%
@%rm -rf \$JOBCOUNTFILE
@%@| @}

Submit a job and write a line in the jobcountfile. The line consists
of the jobnumber, the word ``wait'' and the timestamp in universal seconds.

@d submit a job @{@%
passeer
qsub m4_abindir/m4_jobname | \
 gawk -F"." -v tst=`date +%s`  '{print $1 " wait " tst}' \
 >> \$JOBCOUNTFILE
@< write log @(Updated jobcountfile@) @>
veilig
@| @}


When a job starts, replace "wait" by "run". First find out what the
job number is. The job \textsc{id} begins with the number,
e.g. ~6670732.batch1.irc.sara.nl~. Note the unexpected pattern in the
Bash string replacement instruction.

@d find out the job number @{@%
JOBNUM=\${PBS_JOBID%%.*}
@| @}

@d change ``wait'' to ``run'' in jobcountfile @{@%
@%stmp=`date +%s`
if [ -e \$JOBCOUNTFILE ]
then
  passeer
  mv \$JOBCOUNTFILE \$tmpfil
  gawk -v jid=\$JOBNUM -v stmp=`date +%s` \
    '{ if(match(\$0,"^"jid)>0) {print jid " run  " stmp} else {print}}' \
    \$tmpfil >\$JOBCOUNTFILE
  veilig
  rm -rf \$tmpfil
fi
@| @}

When a job ends, it removes the line:

@d remove the job from the counter @{@%
passeer
mv \$JOBCOUNTFILE \$tmpfil
gawk -v jid=\$JOBNUM  '\$1 !~ "^"jid {print}' \$tmpfil >\$JOBCOUNTFILE
veilig
rm -rf \$tmpfil
@| @}

Periodically check whether jobs have been killed before completion and
have thus not been able to remove their line in the jobcountfile. To
do this, write the jobnumbers in a temporary file and then check the
jobcounter file in one blow, to prevent frequent locks.


@d do brief check of expired jobs @{@%
obsfil=`mktemp --tmpdir obs.XXXXXXX`
rm -rf \$obsfil
@< make a list of jobs that produced logfiles @(\$obsfil@) @>
@< compare the logfile list with the jobcounter list @(\$obsfil@) @>
rm -rf \$obsfil
@| @}

@d do the frequent tasks @{@%
@< do brief check of expired jobs @>
@| @}

@%@d do thorough check of expired jobs @{@%
@%@< check whether update is necessary @(\$thoroughjobcheckfil@,180@,thoroughjobcheck@) @>
@%if \$thoroughjobcheck
@%then
@%@% @< skip brief jobcheck @>
@% @< verify jobs-bookkeeping @>
@%fi
@%@| @}




When a job has ended, a logfile, and sometimes an error-file, is
produced. The name of the logfile is a concatenation of the jobname, a
dot, the character \verb|o| and the jobnumber. The error-file has a
similar name, but the character \verb|o| is replaced by
\verb|e|. Generate a sorted list of the jobnumbers and
remover the logfiles and error-files:

@d make a list of jobs that produced logfiles @{@%
for file in m4_jobname.o*
do
  JOBNUM=\${file<!##!>m4_jobname.o}
  echo \${file<!##!>m4_jobname.o} >>\$tmpfil
  rm -rf m4_jobname.[eo]\$JOBNUM
done
sort < \$tmpfil >@1
rm -rf \$tmpfil
@| @}

Remove the jobs in the list from the counter file if they occur there.

@d compare the logfile list with the jobcounter list @{@%
if [ -e \$JOBCOUNTFILE ]
then
  passeer
  sort < \$JOBCOUNTFILE >\$tmpfil
  gawk -v obsfil=@1 ' 
    BEGIN {getline obs < obsfil}
    { while((obs<\$1) && ((getline obs < obsfil) >0)){}
      if(obs==\$1) next;
      print
    }
  ' \$tmpfil >\$JOBCOUNTFILE
  veilig
fi
rm -rf \$tmpfil
@| @}

From time to time, check whether the jobs-bookkeeping is still
correct.
To this end, request a list of jobs from the operating
system. 

@d verify jobs-bookkeeping @{@%
actjobs=`mktemp --tmpdir act.XXXXXX`
rm -rf \$actjobs
qstat -u  phuijgen | grep m4_jobname | gawk -F"." '{print \$1}' \
 | sort  >\$actjobs
@< compare the active-jobs list with the jobcounter list @(\$actjobs@) @>
rm -rf \$actjobs
@| @}

@d do the now-and-then tasks @{@%
@< verify jobs-bookkeeping @>
@| @}


@d compare the active-jobs list with the jobcounter list @{@%
if [ -e \$JOBCOUNTFILE ]
then
  passeer
  sort < \$JOBCOUNTFILE >\$tmpfil
  gawk -v actfil=@1 -v stmp=`date +%s` ' 
    @< awk script to compare the active-jobs list with the jobcounter list @>
  ' \$tmpfil >\$JOBCOUNTFILE
  veilig
  rm -rf \$tmpfil
else
  cp @1 \$JOBCOUNTFILE
fi
@| @}

Copy lines from the logcount file if the jobnumber matches a line in
the list actual jobs. Write entries for jobnumbers that occur only in
the actual job list.

@d awk script to compare the active-jobs list with the jobcounter list @{@%
BEGIN {actlin=(getline act < actfil)}
{ while(actlin>0 && (act<\$1)){ 
     print act " wait " stmp;
     actlin=(getline act < actfil);
  };
  if((actlin>0) && act==\$1 ){
     print
     actlin=(getline act < actfil);
  }
}
END {
    while((actlin>0) && (act ~ /^[[:digit:]]+/)){
      print act " wait " stmp;
    actlin=(getline act < actfil);
 };
}
@| @}


\subsubsection{Submit extra jobs}
\label{sec:submit}

Check how many files have to be parsed (\verb|NRFILES|) and how many
jobs there are (\verb|NRJOBS|). If there are more than m4_filesperjob
files per job, submit extra jobs.

When before submitting jobs it turns out that, although no job is
running at all, there are files in \verb|proctray|. In that case, they
can be moved back to the intray.


@d check/perform every time @{@%
@< replace files from proctray when no processes are running @>
@< submit jobs when necessary @>
@| @}




@d submit jobs when necessary @{@%
@%@< get number of jobs and number of input files @(NRJOBS@,NRFILES@) @>
NRFILES=`ls -1 \$INBAK |  wc -l`
if [ -e \$JOBCOUNTFILE ]
then
  NRJOBS=`wc -l < \$JOBCOUNTFILE`
else
  NRJOBS=0
fi
@< derive number of jobs to be submitted @(SUBJOBS@) @>
@< write log @(start \$SUBJOBS jobs@) @>
@< submit extra jobs @(SUBJOBS@) @>
@| @}

@d submit extra jobs @{@%
for ((a=1; a <= @1;  a++))
do
  @< submit a job @>
done
@| @}


@d derive number of jobs to be submitted  @{@%
REQJOBS=\$(( \$(( \$NRFILES / m4_filesperjob )) ))
if [ \$NRFILES -gt 0 ]
then
  if [ \$REQJOBS -eq 0 ]
  then
    REQJOBS=1
  fi
fi
@1=\$(( \$REQJOBS - \$NRJOBS ))

@| @}



 

\subsection{The parse job}
\label{sec:parsejob}

Now let us generate the code for the jobs that can be submitted by the
process manager and that perform the actual parsing work. Currently a
job requests only a single node and it runs for half an hour
maximum. 

A job checks whether there is something to do, otherwise it stops.

@d do not run when the intray is empty @{@%
NRFILES=`ls -1 \$INBAK |  wc -l`
if [ \$NRFILES -eq 0 ]
then
  @< write log @(Nothing to do. Quit.@) @>
  exit
fi
@| @}


@d PBS job parameters @{@%
<!#!>PBS -lnodes=m4_nr_of_nodes
<!#!>PBS -lwalltime=m4_walltime
@| @}


@o  m4_bindir/m4_jobname -t @{@%
@< PBS job parameters @>
STARTTIME=`date +%s`
@< init logfile @(m4_jobname@)@>
@< synchronisation functions @>
@< define variables for filenames @>
@< do not run when the intray is empty @>
@< create name for tempfile @>
@< find out the job number @>
PROGNAM=<!!>m4_jobname<!!>\$JOBNUM
@< write log @(start@) @>
@< change ``wait'' to ``run'' in jobcountfile @>
@%@< variables of alpars @>
@< load sara modules @>
@< functions in alpars @>
@< set environments for the NLP applications @>
@%@< install alpino in the local filesystem @>
@%@< set Alpino configuration parameters @>
cd \$TMPDIR
@< start parallel processes that perform the parsing @>
@%@< start notification process @>
wait
@< remove the job from the counter @>
@< write log @(stop@) @>
exit
@| @}

Sara developed modules to facilitate job tasks. We will use module
\verb|disparm|~\footnote{\url{https://www.sara.nl/systems/lisa/software/disparm}},
to retrieve the number of cores that are available.

@d load sara modules @{@%
module load disparm
@| disparm @}

@%Unpack Alpino in the local (scratch) filesystem and make it ready to
@%run. I am not sure while it is better to first copy the tarball and
@%then unpack it or to unpack the tarball directly from the home filesystem.

Set environment variables for the NLP applications. Currently only
Alpino is a known and supported application.

Set the variables \verb|ALPINO_HOME| and \verb|PATH|.

@d set environments for the NLP applications @{@%
export ALPINO_HOME=\$HOME/nlp/Alpino
export PATH=\$PATH:\$ALPINO_HOME/bin
@%export ALPINO_HOME=\$TMPDIR/Alpino
@%export PATH=\$PATH:\$ALPINO_HOME/bin
@| @}


@%@d install alpino in the local filesystem @{@%
@%ALPTARBALL=m4_alpinotarball
@%cd \$TMPDIR
@%cp \$HOME/alpino/\$ALPTARBALL .
@%tar -xzf \$ALPTARBALL
@%rm -rf \$ALPTARBALL
@%export ALPINO_HOME=\$TMPDIR/Alpino
@%export PATH=\$PATH:\$ALPINO_HOME/bin
@%@| ALPINO_HOME PATH ALPTARBALL @}

Set variables to configure Alpino. Gert-Jan van Noort wrote in a
personal communication that the following two parameters must be set
in order to have Alpino produce correct \UTF{}:

@d set environments for the NLP applications @{@%
export SP_CSETLEN=212 
export SP_CTYPE=utf8 
@| SP\_CSETLEN SP\_CTYPE@}


Find out how many cores there are and then create the same number of
parallel processes. The number of cores can be obtained from variable
\verb|sara-get-num-cores| that is supplied by the \verb|disparm|
module. Generate a file \verb|proctal| that contains the number of processes that
actually runs.

@d start parallel processes that perform the parsing @{@%
echo 0 >\$TMPDIR/proctal
export NCORES=`sara-get-num-cores`
echo "Node has " \$NCORES " cores".
PROCNUM=0
for ((i=1; i<= NCORES ; i++)) ; do
  ( echo Process number: \$PROCNUM
    @< increment filecontent @(\$TMPDIR/proctal@) @>
    echo \$PROCNUM: Proctal after increment: `cat \$TMPDIR/proctal`
    @< perform a single process @>
    @< decrement filecontent @(\$TMPDIR/proctal@) @>
    echo \$PROCNUM: Proctal after decrement: `cat \$TMPDIR/proctal`
  ) &
  PROCNUM=\$((\$PROCNUM + 1))
done
@| @}


Each process repeats the following:
\begin{enumerate}
\item Select a file from the in-tray
\item Move it to the process-tray
\item Copy it to a temporary file on the local filesystem
\item Run Alpino on it.
\item Copy the result to the out-tray.
\item Send the result to the user.
\item Remove the source from the process-tray
\end{enumerate}


This code is a bit demo-style. When the input-file is moved into the
process-tray it should get a name that links it to this process, to
facilitate moving it back to the intray when this process dies
prematurely. 

The function \verb|getfile| stores a filename in variable
\verb|FILNAM| and moves the input-file with this name
to the process-tray. Its result reflects whether it actually found a file.

To keep track of the time needed to perform the parsing, the
processing time will be measured and recorded in a bookkeepfile.

@d define variables for filenames @{@%
export BOOKKEEPFILE=m4_bookkeepfile
@| BOOKKEEPFILE @}


Note that, to use the time command with its arguments, the ``time''
command must be given as the full path to the binary (see
\url{https://bugs.launchpad.net/ubuntu/+source/time/+bug/220512}).

@d perform a single process @{@%
@%getfile
@%while [ \$? -eq 0 ]
while getfile
do
  BTIME=`date +%s`
  echo Got file \$FILNAM
  INFIL=`mktemp --tmpdir`
  OUTFIL=`mktemp --tmpdir`
  rm -rf \$INFIL
  rm -rf \$OUTFIL
  cp \$PROCBAK/\$FILNAM \$INFIL
  @< generate format for time command @(TIMEFORMAT@) @>
  @< construct the alpino command @(\$INFIL@) @>
  @< apply the alpino command @(\$INFIL@,\$OUTFIL@) @>
  @< send the output to the sender @>
  echo \$FILNAM processed
  ETIME=`date +%s`
  @< log time lapse @>
@%  getfile
done
@| @}



Make a list of the files that have been processed, relevant properties
and the wall-times that they needed. The list has the following
columns: 1) filesize; 2) wall time; 3) filename and 4) processing
command.

@d log time lapse @{@%
@%passeer
echo `stat --printf="%s" \$INFIL`"	\$((\$ETIME - \$BTIME))	\$FILNAM	\$ALPCOMMAND" >> \$BOOKKEEPFILE
@%veilig
@| @}


@d generate format for time command @{@%
@1=`stat --printf="%s" \$INFIL`"\t%e\t\$FILNAM\t\$ALPCOMMAND" 
@| @}



@%The function \verb|getfile| does the following: When there are files
@%in the input-tray it selects the name of the largest file, stores the
@%name in variable \verb|FILNAM| and moves the file into the
@%process-tray. When this is successful, it returns value~0, otherwise
@%value~1. The selection and moving operations are protected with the
@%synchronisation mechanism.

The function \verb|getfile| does the following: When there are files
in the input-tray it selects the name of the largest file, stores the
name in variable \verb|FILNAM| and moves the file into the
process-tray. When the input-tray is empty, the function sleeps a while and then retries.


 When this is successful, it returns value~0, otherwise
@%value~1. The selection and moving operations are protected with the
@%synchronisation mechanism.




@d functions in alpars @{@%
filefind()
{
  while
    @< fetch a file from the intray @(FILNAM@) @>
@%    FILNAM=`ls -1S \$INBAK 2>/dev/null | head -n 1`
    [ -z "\$FILNAM" ]
  do 
@%   sleep 10s
    waitabit
  done
}
@| @}


Fetch a file from the intray by moving it to the outtray. File
movement ought to be an atomic operation, so two processes cannot move
the same file at the same time. When less than  half of the time
alotted to this job has been expired, fetch the largest file from the
intray. Otherwise, fetch the smallest file.

@d fetch a file from the intray @{@%
NOW=`date +%s`
if [ \$((NOW - STARTTIME)) -lt m4_wallhalfsecs ]
then
  @1=`ls -1S \$INBAK 2>/dev/null | head -n 1`
else
  @1=`ls -1rS \$INBAK 2>/dev/null | head -n 1`
fi
@| @}


@d functions in alpars@{@%
function getfile () {
  while filefind
  do
    if ( set -o noclobber; cat \$INBAK/\$FILNAM > \$PROCBAK/\$FILNAM ) 2> /dev/null;
    then
       waitabit
@%      sleep 1s
@%      mv \$INBAK/\$FILNAM \$PROCBAK 2>/dev/null
      break
    fi
  done
  rm -f \$INBAK/\$FILNAM
  touch \$PROCBAK/\$FILNAM
}

@| getfile @}


The job expects that the first line of input documents contains a
she-bang, followed by the Alpino command to be applied. Hence, proceed
as follows:
\begin{enumerate}
\item Extract the Alpino command and put it in variable \verb|AWCOMMAND|.
\item Apply the Alpino command on the ``tail'' of the input file
\item Remove the temporary file.
\end{enumerate}

@%@d construct the alpino command and apply it @{@%
@%COMFIL=`mktemp --tmpdir`
@%rm -rf \$COMFIL
@%gawk 'NR==1 {gsub(/^#!/, "");print}' @1 >\$COMFIL
@%@< look for an xml-treebank request @>
@%chmod 775 \$COMFIL
@%gawk 'NR>1' @1 | \$COMFIL >@2
@%rm -rf \$COMFIL 
@%@| @}


@d apply the alpino command @{@%
@%AWCOMMAND='NR==1 {gsub(/^#!/, "");print}'
@%ALPCOMMAND=`gawk "\$AWCOMMAND" @1`
TIMEOUT=false
timeout m4_timeoutsecs<!!>s bash -c "gawk 'NR>1' @1 | \$ALPCOMMAND >@2 2>/dev/null"
if [ \$? -eq m4_timeoutexit ] 
then
  TIMEOUT=true
  @< write log @(\$FILNAM time-out@) @>
@%  mv \$PROCBAK/\$FILNAM \$TOOOBAK
fi
@| @}

@d construct the alpino command @{@%
AWCOMMAND='NR==1 {gsub(/^#!/, "");print}'
ALPCOMMAND=`gawk "\$AWCOMMAND" @1`
@< look for an xml-treebank request @(ALPCOMMAND@) @>
@| @}


As far as I see, Alpino has a mode in which it produces a single
output file, but there is also a mode in which it produces a directory
with an xml-file for each sentence. To request a directory with
xml-files, the user writes -XMLTREEBANK as option.

When the user has done that, generate a temporary directory with a
directory to store the xml files. At the end of the job, we pack this
directory in a tarball and return that.

In contrast with what the name of the macro suggests, the file will
not be sent by-e-mail, because it seems that the mail system of Lisa
is not capable to process a large amount of texts.

@%@d look for an xml-treebank request @{@%
@%XMLTREEBANK=`grep "-XMLTREEBANK" <\$COMFIL | wc -l`
@%if [ \$XMLTREEBANK -ge 1 ]
@%then
@%  XMLDIR=`mktemp --tmpdir -d xml.XXXXXX`
@%  gawk '{gsub(/-XMLTREEBANK/, aap); print}' aap="-flag treebank \$XMLDIR  -end_hook xml"
@%fi
@%@| @}

@d look for an xml-treebank request @{@%
if [ `echo \$ALPCOMMAND | grep -e "-XMLTREEBANK" | wc -l` -ge 1 ]
then
  XTMPDIR=`mktemp --tmpdir -d XML.XXXXXX`
  XMLDIR=\$XTMPDIR/xml
  mkdir \$XMLDIR
  echo Directory \$XMLDIR
  AWCOMMAND='{gsub("-XMLTREEBANK", "-flag treebank '\$XMLDIR' -flag end_hook xml");print}'
  echo \$AWCOMMAND
  ALPCOMMAND=`echo \$ALPCOMMAND | gawk "\$AWCOMMAND"`
  echo \$ALPCOMMAND
else 
  XMLDIR=
fi
@| @}


If timeout has occurred, move the original file from the proctray to
the timeout tray. Otherwise, remove that file and write the output of
the parsing to a file in the outtray.

@d send the output to the sender @{@%
if \$TIMEOUT
then
  @< write log @(\$FILNAM to time-out tray@) @>
  mv \$PROCBAK/\$FILNAM \$TOOOBAK
else
  if [ "\$XTMPDIR" = "" ]
  then
    @< write log @(Send \$OUTFIL to \$UITBAK/\$FILNAM@)@>
     mv \$OUTFIL \$UITBAK/\$FILNAM
@% ( cd \$UITBAK && biabam \$FILNAM -s "Alpinoparse"  \$USER </dev/null )
  else
@%  @< pack the xml-directory in outtray and remove xml directory @>
    echo Send xml-directory to \$UITBAK/\$FILNAM
    @< pack/send the xml-directory and remove xml directory @>
  fi
  rm \$PROCBAK/\$FILNAM
fi
@| @}


@%@d send the output to the out-tray @{@%
@%if [ "\$XTMPDIR" = "" ]
@%then
@%  mv \$OUTFIL \$UITBAK/\$FILNAM
@%else
@%  @< pack the xml-directory in outtray and remove xml directory @>
@%fi
@%@| @}

Pack the directory with the \XML{} files in a tarball, put the tarball
in the outtray and then remove the temporary directory and the
\texttt{XTMPDIR} variable.

@%@d pack the xml-directory in outtray and remove xml directory @{@%
@%(
@%  cd \$XTMPDIR
@%  tar -czf \$FILNAM xml
@%  mv \$FILNAM \$UITBAK
@%)
@%rm -rf \$XTMPDIR
@%XTMPDIR=
@%@| @}

@d pack/send the xml-directory and remove xml directory @{@%
(
  cd \$XTMPDIR
  tar -czf \$FILNAM xml
@%  biabam \$FILNAM -s "Alpinoparse"  \$USER </dev/null
  mv \$FILNAM \$UITBAK
)
rm -rf \$XTMPDIR
XTMPDIR=
@| @}

\subsubsection{Notification}
\label{sec:notification}

Report to the intermediate server what is going on, on a minutely
basis. 

@%This is done by a separate process. It checks whether there are
@%still parsing processes running and stops if that is the case.

@%@d start notification process @{@%
@%(
@% echo Start notify: `cat \$TMPDIR/proctal`
@% while [ `cat \$TMPDIR/proctal` -gt 0 ]
@% do
@%   echo notify loop: `cat \$TMPDIR/proctal`
@%   @< send notice when it is time @>
@%
@%   sleep 60
@% done  
@%) &
@%@| @}




@%@d send report when it is time @{@%
@%@< check whether update is necessary @(m4_notifile@,60@,notif@) @>
@%if \$notif
@%then
@%  @< send notification @>
@%else
@%  echo No report.
@%fi
@%@| @}

@%@d check/perform every time @{@%
@%@< send notification @>
@%@| @}

@%@d send notification @{@%
@%NOTFIL=`mktemp --tmpdir not.XXXXXX`
@%echo intray: > \$NOTFIL
@%ls -1 \$INBAK >>\$NOTFIL
@%echo proctray: >> \$NOTFIL
@%ls -1 \$PROCBAK >>\$NOTFIL
@%echo outtray: >> \$NOTFIL
@%ls -1 \$UITBAK >>\$NOTFIL
@%cat \$NOTFIL | mail -s Alpinostatus \$USER
@%@%echo -----notfil---------
@%@%cat \$NOTFIL
@%@%echo -----/notfil---------
@%rm -rf \$NOTFIL
@%@< write log @(notification sent@) @>
@%@| @}

@d print notification @{@%
@%NOTFIL=`mktemp --tmpdir not.XXXXXX`
@< make list of tray @(intray@,\$INBAK@) @>
@< make list of tray @(proctray@,\$PROCBAK@) @>
@< make list of tray @(outtray@,\$UITBAK@) @>
@< make list of tray @(toootray@,\$TOOOBAK@) @>
@< report processors @>
@%echo intray:
@%ls -1 \$INBAK
@%echo proctray:
@%ls -1 \$PROCBAK
@%echo outtray:
@%ls -1 \$UITBAK
@< write log @(notification sent@) @>
@| @}

@d make list of tray @{@%
echo @1:
ls -1 @2
@| @}

@d report processors @{@%
echo processors: `grep run .jobcount | wc -l`
@| @}


\subsection{Process manager}
\label{sec:procesmanager}

The process manager is a cron-job that is started periodically, but it
is also started when a new file has been uploaded.

@o m4_bindir/alpinomanager @{@%
#!/bin/bash
@< init logfile @(alpinomanager@)@>
@< write log @(start@) @>
@< create name for tempfile @>
@< synchronisation functions @>
@< stop if another alpinomanager is running @>
@< define variables for filenames @>
@< perform the management tasks @>
@%@< check expired jobs @>
@%@< restore old files from the process-tree @>
@%@< remove old files from the outtray @>
@%@< submit jobs when it is necessary @>
@< write log @(stop@) @>
@| @}

\subsubsection{When will the manager run}
\label{sec:whenmanager}

The process manager could run as a cron-job in the
background. However, we presume that this service will either be used
intensively or not at all. Hence it makes sense that user requests
start the alpinomanager at regular times.

@d start the alpinomanager @{@%
@%@< check whether update is necessary @(m4_alpinocheckfile@,m4_managerperiod@,alprun@) @>
@%if \$alprun
@%then
( m4_abindir/alpinomanager )

@%fi
@| @}


Prevent that more than one instance of the program runs. I don't know
whether this is a really safe way. Note that the \verb|ps| command
gives a line for this alpinomanager and for the \verb|ps| command as well.

@d stop if another alpinomanager is running @{@%
COUNT=`ps -A |grep alpinomanager | wc -l`
if [ \$COUNT -ge 3 ]
then
  exit
fi
@| COUNT @}

\subsubsection{Frequent tasks and less frequent tasks}
\label{sec:tenhalf}

The jobmanager performs some tasks every time that it is started,
some other tasks at intervals of about five minutes and yet other
tasks every half hour. The time interval is controlled by the
date-stamps of indicator-files. When the file has been touched too
long ago or when it does not exist, the tasks belonging to that file
are performed and the file is touched.


@d perform the management tasks @{@%
frequentcheckfile=m4_frequentcheckfile
now_and_then_checkfile=m4_now_and_then_checkfile
frequentcheckperiod=300
now_and_then_checkperiod=1800
@< check/perform now-and-then tasks @>
@< check/perform frequent tasks @>
@< check/perform every time @>
@| @}

@d check/perform now-and-then tasks @{@%
@< check whether update is necessary @(now_and_then_checkfile@,\$now_and_then_checkperiod@,checkb@) @>
if \$checkb
then
@< write log @(now-and-then tasks@) @>
@< do the now-and-then tasks @>
fi
@| @}



@d check/perform frequent tasks @{@%
@< check whether update is necessary @(frequentcheckfile@,\$frequentcheckperiod@,checkb@) @>
if \$checkp
then
@< write log @(frequent tasks@) @>
@< do the frequent tasks @>
fi
@| @}

Currently we assume that the parser is capable to process an
input-file within half an our. Hence, files that have been longer than
that time in the process-tray are assumed to be left-overs.

@d restore old files from the process-tree @{@%
NRFILES=`ls -1 \$PROCBAK 2>/dev/null |  wc -l`
if [ "\$NRFILES" != "0" ] 
then
  find \$PROCBAK/* -amin m4_parsetimeout -print 2>/dev/null | xargs -Iaap mv aap  \$INBAK
fi
@| @}

Furthermore, when no processes are running, we can move all files from
the proctray into the intray.

@d replace files from proctray when no processes are running @{@%
@< determine number of running processes @(RUNPROCCOUNT@) @>
if [ "\$RUNPROCCOUNT" == "0" ]
then
  NRFILES=`ls -1 \$PROCBAK 2>/dev/null |  wc -l`
  if [ "\$NRFILES" != "0" ] 
  then
    find \$PROCBAK/*  -print 2>/dev/null | xargs -Iaap mv aap  \$INBAK
  fi
fi
@| @}

@d determine number of running processes @{@%
if [ -e \$JOBCOUNTFILE ]
then
@1=`gawk 'BEGIN {runprocs=0}; /run/ {runprocs++}; END {print runprocs}' \$JOBCOUNTFILE`
else
 @1=0
fi
@| @}



Remove files that have been waiting too long before retrieval.

@d remove old files from the outtray @{@%
NRFILES=`ls -1 \$UITBAK 2>/dev/null |  wc -l`
if [ "\$NRFILES" != "0" ] 
then
  find \$UITBAK/* -atime m4_outtraytimeout -print | xargs rm -rf
fi
@| @}

@d do the frequent tasks @{@%
@< restore old files from the process-tree @>
@| @}

@d do the now-and-then tasks @{@%
@< remove old files from the outtray @>
@| @}



@%\subsubsection{Manage the number of jobs}
@%\label{sec:manageprocesses}
@%
@%Start parse processes to process incoming files. Let us say that we
@%want one job to process m4_filesperjob incoming texts. We need the
@%following variables:
@%\begin{description}
@%\item[NRJOBS:] Number of jobs that is currently running;
@%\item[REQJOBS:] Required number of jobs;
@%\item[NRFILES:] Number of files to be processed. 
@%\end{description}
@%
@%From these variables, derive the number of extra jobs to be
@%submitted. At least one job must exist if at least one file is
@%waiting to
@%
@%
@%
@%Find out how many parse jobs are currently running. This is a bit
@%complicated because it seems that the request to obtain the number of
@%processes waiting and running is too resource-intensive to be
@%performed on a regular basis. Therefore, we try some bookkeeping and
@%store the number of jobs that we assume are running or waiting in file
@%\verb|\$JOBCOUNTFILE|.  When we submit a job we increment this
@%number. When a job ends regularly, it decrements the number.
@%
@%
@%Generate a file that keeps track when the number of processes have
@%been checked the last time:
@%
@%@d get number of current jobs @{@%
@%@< check whether update is necessary @(m4_jobcheckfile@,900@,RECHECK@) @>
@%if \$RECHECK
@%then
@%  @< count running and waiting jobs @>
@%fi
@%NR
@%@| @}
@%
@%@d count running and waiting jobs @{@%
@%passeer
@%echo `qstat -u  phuijgen | grep m4_jobname |wc -l` >\$JOBCOUNTFILE
@%veilig
@%@| @}


@%\begin{verbatim}
@%
@%ACTIVE JOBS--------------------
@%JOBNAME            USERNAME      STATE  PROC   REMAINING            STARTTIME
@%
@%6470805            phuijgen    Running    16    00:01:00  Sat Sep 22 19:35:13
@%
@%     1 Active Job     3892 of 6564 Processors Active (59.29%)
@%                       409 of  632 Nodes Active      (64.72%)
@%
@%IDLE JOBS----------------------
@%JOBNAME            USERNAME      STATE  PROC     WCLIMIT            QUEUETIME
@%
@%
@%0 Idle Jobs
@%
@%BLOCKED JOBS----------------
@%JOBNAME            USERNAME      STATE  PROC     WCLIMIT            QUEUETIME
@%
@%
@%Total Jobs: 1   Active Jobs: 1   Idle Jobs: 0   Blocked Jobs: 0
@%
@%\end{verbatim}
@%
@%To obtain the number of running jobs, output the result of the
@%\verb|qstat| command and count the number of times that the jobname
@%occurs.
@%
@%\begin{verbatim}
@%batch1.irc.sara.nl: 
@%                                                                         Req'd  Req'd   Elap
@%Job ID               Username Queue    Jobname          SessID NDS   TSK Memory Time  S Time
@%-------------------- -------- -------- ---------------- ------ ----- --- ------ ----- - -----
@%6470857.batch1.i     phuijgen express  testjob           19043     1   1    --  00:01 R   -- 
@%
@%\end{verbatim}


@%@d get number of jobs and number of input files @{@%
@%@1=`qstat -u  phuijgen | grep m4_jobname |wc -l`
@%@2=`ls -1 \$INBAK |  wc -l`
@%@| @}


\subsection{Upload script}
\label{sec:uploadscript}

An external computer can connect to Lisa by way of \verb|ssh| and run
the following script \verb|download| to upload a file. The name of the
file is given as argument and the contents is written to standard in.

To prevent that during the download a parse-process grabs the still
incomplete file, the contents of the file is first collected into a
temporary file. Then the file is moved to the intray (note that a move
is an atomic action). Finally the alpinomanager is started. 

@o m4_bindir/download @{@%
#!/bin/bash
# Download .. Download a file to be processed
# Filename is argument
# File contents from standard in
@< init logfile @(download@) @>
@< write log @(start@) @>
@< cd naar werkdir @>
@< create name for tempfile @>
@< synchronisation functions @>
@< define variables for filenames @>
DESTNAME=\$1
DESTFILE=\$INBAK/\$DESTNAME
@%TMPNAME=`mktemp --tmpdir tmp.XXXXXX`
@%rm -rf \$TMPNAME
cat > \$tmpfil
mv \$tmpfil \$DESTFILE
@< write log @(start alpinomanager @) @>
@< start the alpinomanager @>
@< write log @(alpinomanager finished@) @>
@%m4_abindir/alpinomanager
@%@< submit jobs when it is necessary @>
@< write log @(stop@) @>
exit
@| @}

@d cd naar werkdir @{@%
cd m4_aprojroot
@| @}

An alternative is, to upload a tar archive with files. This has the
advantage that less \textsc{ssh} connections with Lisa are needed. 

@o m4_bindir/download_archive  @{@%
#!/bin/bash
# Download .. Download a tar archives with files to be processed
# Filename is argument
# File contents from standard in
@< init logfile @(download_archive@)@>
@< write log @(start@) @>
@< cd naar werkdir @>
@< create name for tempfile @>
@< synchronisation functions @>
@< define variables for filenames @>
@< unpack tar @>
@< write log @(start alpinomanager@) @>
@< start the alpinomanager @>
@%m4_abindir/alpinomanager
@%@< submit jobs when it is necessary @>
@< write log @(stop@) @>
exit
@| @}


Unpack in a temporary directory to prevent that a job picks
prematurely up a half-unpacked file.

@d unpack tar @{@%
tmpdir=`mktemp --tmpdir -d tmpd.XXXXXX`
cd \$tmpdir
tar -xzf - 
mv * \$INBAK
cd m4_aprojroot
rm -rf \$tmpdir
@| @}



\subsection{State script}
\label{sec:statescript}

The external computer can connect to Lisa by way of \verb|ssh| and ask
for the status of a file that are to be processed. If that happens,
Lisa send a list of the contents of the trays by e-mail and then returns the status of the file 
 in the argument. The status can be 1)
\verb|waiting|; 2) \verb|being processed|; 3) \verb|ready| or 4)
\verb|unknown|.

@o m4_bindir/filstat @{@%
#!/bin/bash
# filstat: provide state of files
# Filename is argument
@< init logfile @(filstat@)@>
@< write log @(start@) @>
@< synchronisation functions @>
@< define variables for filenames @>
@< write log @(start alpinomanager@) @>
@< start the alpinomanager @>
@< write log @(alpinomanager ended@) @>
@%@< write log @(send notification@) @>
@< print notification @>
@%@< send notification @>
@%touch m4_notifile
@%@< create name for tempfile @>
@%@< define variables for filenames @>
@%FILENAME=\$1
@%@< write log @(pass state of \$FILENAME@)@>
@%if [ -e \$INBAK/\$FILENAME ]
@%then
@%  echo "waiting"
@%elif [ -e \$PROCBAK/\$FILENAME ]
@%then
@%  echo "being processed"
@%elif [ -e \$UITBAK/\$FILENAME ]
@%then
@%  echo "ready"
@%else
@%  echo "unknown"
@%fi
@< write log @(stop@) @>
@| @}

\subsection{Download script}
\label{sec:download}

An external computer can connect to Lisa by way of \verb|ssh| and
run the following script \verb|upload| to download a file. The name of the file is
given as argument and the contents is written to standard out.

@o m4_bindir/upload @{@%
#!/bin/bash
# Upload .. upload a parse
# Filename is argument
@< init logfile @(upload@)@>
@< create name for tempfile @>
@< define variables for filenames @>
FILNAM=\$1
if [ -e \$UITBAK/\$FILNAM ]
then
 cat \$UITBAK/\$FILNAM
 rm -rf \$UITBAK/\$FILNAM
else
 echo "unknown: \$UITBAK/\$FILNAM"
fi
m4_abindir/alpinomanager
@| @}



@%\section{What to do?}
@%\label{sec:whattodo}

@%@d  expliciete make regels @{@%
@%m4_abindir/m4_progname.py: m4_progname.w
@%	nuweb -t m4_progname.w
@%
@%run : m4_abindir/m4_progname.py 
@%	cd m4_abindir && chmod 775 ./run_spitsnieuwsscraper
@%	cd m4_abindir && ./run_spitsnieuwsscraper
@%
@%@| @}
@%
@%
@%@o m4_abindir/run_spitsnieuwsscraper @{@%
@%#!/bin/bash
@%export DJANGO_SETTINGS_MODULE="amcat.settings"
@%if [ -z "\$PYTHONPATH" ]
@%then
@%  export PYTHONPATH=m4_amcatpath
@%else 
@%  export PYTHONPATH=m4_amcatpath:\$PYTHONPATH
@%fi
@%echo PYTHONPATH: \$PYTHONPATH
@%OLDDIR=`pwd`
@%cd m4_abindir
@%python spitsnieuws.py 1 2012-02-20
@%@| @}
@%
@%@d make executables executable @{@%
@%	chmod 775 m4_abindir/run_spitsnieuwsscraper
@%@| @}

\subsection{Download a directory with scripts}
\label{sec:downloaddir}

Instead of using standard services, a user can create a directory with
software and use that software. The following script downloads and
unpacks a directory. It gets the name of the directory root as
argument and only if that is the correct name of the root directory
in the tarball, the directory will be accepted.

When the script performed its task correctly it prints
``OK''. Otherwise, it prints ``error''.


@o m4_bindir/downloaddir @{@%
#!/bin/bash
# downloaddir -- Download a directory with software
# Directory name is argument
# Tarball from standard in
EXITSTATE=0
@< init logfile @(downloaddir@)@>
@< write log @(start@) @>
@< get the argument of the downloaddir script @>
@< create a tempdir for downloaddir @>
@< test and unpack the tarball @>
@< remove the tempdir for downloaddir @>
@< write log @(stop@) @>
@< echo exitstate @>
exit \$EXITSTATE
@| @}

@d echo exitstate @{@%
if
  [ \$EXITSTATE -eq 0 ]
then 
  echo OK
else 
  echo error
fi
@| @}

@d get the argument of the downloaddir script @{@%
DIRROOT=\$1
if
 [ -z "\$DIRROOT" ]
then
 echo error
 @< write log @(Stop: no argument@) @>
 exit 4
fi
@| @}

Create/remove a temporary directory to unpack the received
tarball. Put the directory in the home filesystem, because then the
contents can easily be moved to its final place in the same filesystem.

@d create a tempdir for downloaddir @{@%
OLDD=`pwd`
cd ~/
tmpdir=`mktemp -d tarbal.XXXXXXX`
cd \$tmpdir
@| tmpdir @}

@d remove the tempdir for downloaddir @{@%
cd ..
rm -rf \$tmpdir
cd \$OLDD
@| @}

The tarball ought to contain a directory-tree with as root the name of the
submitter, that has been given as argument. This directory ought to be
moved to its right place. However, this is a dangerous
operation. Every subdirectory could be overwritten if the root
directory has a wrong name. Therefore, we have list of allowed names,
and compare the name of the imported  root with the list. 

Note, that the \texttt{mv} operation does not move a directory if
the target directory already exists. Therefore we have to remove the
target directory first. Users must keep a clone of the directory tree
and upload modificated clones of the complete directory tree. 

So, proceed as follows: 1)
unpack the tarball in the temporary directory; 2) Find the name of the
root directory; 3) compare with a list of allowed names; 4) remove the
target directory if it exists; 5) move the uploaded directory to its
proper place; 6) echo ``OK'' when this was successfull and
``error'' otherwise.

@d test and unpack the tarball @{@%
tar -xzf - 2>/dev/null
EXITSTATE=\$?
if
  [ \$EXITSTATE -eq 0 ]
then
  @< get the name of the root directory  @>
  @< check whether the rootname is valid @>
  if \$ISVALIDROOT 
  then
@%    @< remove the target directory @>
    @< replace the target directory by the upload @>
  else
    @< write log @(directory \$ROOTNAME not valid@) @>
    EXITSTATE=4
  fi
else
  @< write log @(no valid tarball received@) @>
fi
@| @}


@d get the name of the root directory @{@%
ROOTNAME=`ls -1`
ROOTNAME=\${ROOTNAME%%/*}
@| ROOTNAME @}

@d check whether the rootname is valid @{@%
ISVALIDROOT=false
while read user remainder
do
  if
    [ "\$user" = "\$ROOTNAME" ]
  then
    ISVALIDROOT=true
  fi
done  < m4_userlist
@| @}

@d replace the target directory by the upload @{@%
rm -rf m4_nlprootdir/\$ROOTNAME
if
  mv \$ROOTNAME m4_softwareroot 2>/dev/null
then
@%  echo OK
  @< write log @(wrote directory \$DIRROOT@) @>
else
  @< write log @(directory \$DIRROOT not written@) @>
  EXITSTATE=4
fi
@| @}


@%@d try to move the contents of the tarball @{@%
@%if
@%  mv \$DIRROOT m4_nlprootdir 2>/dev/null
@%then
@%  echo OK
@%  @< write log @(wrote directory \$DIRROOT@) @>
@%else
@%  @< write log @(directory \$DIRROOT not written@) @>
@%  EXITSTATE=4
@%fi
@%@| @}


\appendix

\section{Translate and run}
\label{sec:transrun}

This chapter assembles the Makefile for this project.

@o Makefile -t @{@%
@< default target @>

@< parameters in Makefile @> 

@< impliciete make regels @>
@< expliciete make regels @>
@< make targets @>
@| @}

The default target of make is \verb|all|.

@d  default target @{@%
all : @< all targets @>
.PHONY : all

@|PHONY all @}

One of the targets is certainly the \textsc{pdf} version of this
document.

@d all targets @{m4_progname.pdf@}

We use many suffixes that were not known by the C-programmers who
constructed the \texttt{make} utility. Add these suffixes to the list.

@d parameters in Makefile @{@%
.SUFFIXES: .pdf .w .tex .html .aux .log

@| SUFFIXES @}



\subsection{Pre-processing}
\label{sec:pre-processing}

To make usable things from the raw input \verb|a_<!!>m4_progname`'.w|, do the following:

\begin{enumerate}
\item Process \verb|\$| characters.
\item Run the m4 pre-processor.
\item Run nuweb.
\end{enumerate}

This results in a \LaTeX{} file, that can be converted into a \pdf{}
or a \HTML{} document, and in the program sources and scripts.

\subsubsection{Process dollar characters }
\label{sec:procdollars}

Many ``intelligent'' \TeX{} editors (e.g.\ the auctex utility of
Emacs) handle \verb|\$| characters as special, to switch into
mathematics mode. This is irritating in program texts, that often
contain \verb|\$| characters as well. Therefore, we make a stub, that
translates the two-character sequence \verb|\\$| into the single
\verb|\$| character.

@d expliciete make regels @{@%
m4_<!!>m4_progname<!!>.w : a_<!!>m4_progname<!!>.w
	gawk '{if(match($$0, "@@<!!>%")) {printf("%s", substr($$0,1,RSTART-1))} else print}' a_<!!>m4_progname.w \
          | gawk '{gsub(/[\\][\\$\$]/, "$$");print}'  > m4_<!!>m4_progname<!!>.w
@% $

@| @}


@%@d expliciete make regels @{@%
@%m4_<!!>m4_progname<!!>.w : a_<!!>m4_progname<!!>.w
@%	gawk '{gsub(/[\\][\\$\$]/, "$$");print}' a_<!!>m4_progname<!!>.w > m4_<!!>m4_progname<!!>.w
@%
@%@% $
@%@| @}

Run the M4 pre-processor:

@d  expliciete make regels @{@%
m4_progname<!!>.w : m4_<!!>m4_progname<!!>.w inst.m4 texinclusions.m4
	m4 -P m4_<!!>m4_progname<!!>.w > m4_progname<!!>.w

@| @}

\subsection{Typeset this document}
\label{sec:typeset}

Enable the following:
\begin{enumerate}
\item Create a \pdf{} document.
\item Print the typeset document.
\item View the typeset document with a viewer.
\end{enumerate}

In the three items, a typeset \pdf{} document is required or it is the
requirement itself.

Make a \pdf{} document.

@d make targets @{@%
pdf : m4_progname.pdf

print : m4_progname.pdf
	m4_printpdf(m4_progname)

view : m4_progname.pdf
	m4_viewpdf(m4_progname)

@| pdf view print @}

Create the \pdf{} document. This may involve multiple runs of nuweb,
the \LaTeX{} processor and the bib\TeX{} processor, and dpends on the
state of the \verb|aux| file that the \LaTeX{} processor creates as a
by-product. Therefore, this is performed in a separate script,
\verb|w2pdf|.

\subsubsection{The w2pdf script}
\label{sec:w2pdf}

The three processors nuweb, \LaTeX{} and bib\TeX{} are
intertwined. \LaTeX{} and bib\TeX{} create parameters or change the
value of parameters, and write them in an auxiliary file. The other
processors may need those values to produce the correct output. The
\LaTeX{} processor may even need the parameters in a second
run. Therefore, consider the creation of the (\pdf) document finished
when none of the processors causes the auxiliary file to change. This
is performed by a shell script \verb|w2pdf|

Note, that in the following \texttt{make} construct, the implicit rule
\verb|.w.pdf| is not used. It turned out, that make did not calculate
the dependencies correctly when I did use this rule.

@d  impliciete make regels@{@%
@%.w.pdf :
%.pdf : %.w \$(W2PDF)
	chmod 775 \$(W2PDF)
	\$(W2PDF) \$*

@| @}

@d parameters in Makefile @{@%
W2PDF=./w2pdf
@| @}

@d expliciete make regels  @{@%
\$(W2PDF) : m4_progname.w
	nuweb m4_progname.w
@| @}

@o w2pdf @{@%
#!/bin/bash
# w2pdf -- make a pdf file from a nuweb file
# usage: w2pdf [filename]
#  [filename]: Name of the nuweb source file.
<!#!> m4_header
echo "translate " \$1 >w2pdf.log
@< filenames in w2pdf @>

@< perform the task of w2pdf @>

@| @}

The script retains a copy of the latest version of the auxiliary file.
Then it runs the three processors nuweb, \LaTeX{} and bib\TeX{}, until
they do not change the auxiliary file. 

@d perform the task of w2pdf @{@%
@< run the processors until the aux file remains unchanged @>
@< remove the copy of the aux file @>
@| @}

The user provides the name of the nuweb file as argument. Strip the
extension (e.g.\ \verb|.w|) from the filename and create the names of
the \LaTeX{} file (ends with \verb|.tex|), the auxiliary file (ends
with \verb|.aux|) and the copy of the auxiliary file (add \verb|old.|
as a prefix to the auxiliary filename).

@d filenames in w2pdf @{@%
nufil=\$1
trunk=\${1%%.*}
texfil=\${trunk}.tex
auxfil=\${trunk}.aux
oldaux=old.\${trunk}.aux
@| nufil trunk texfil auxfil oldaux @}

Remove the old copy if it is no longer needed.
@d remove the copy of the aux file @{@%
rm \$oldaux
@| @}

Run the three processors. Do not use the option \verb|-o| (to suppres
generation of program sources) for nuweb,  because \verb|w2pdf| must
be kept up to date as well.

@d run the three processors @{@%
nuweb \$nufil
m4_latex(\$texfil)
bibtex \$trunk
@| nuweb pdflatex bibtex @}


Repeat to copy the auxiliary file an run the processors until the
auxiliary and a copy do both exist and are equal to each other.

@d run the processors until the aux file remains unchanged @{@%
while
 ! cmp -s \$auxfil \$oldaux
do
  if [ -e \$auxfil ]
  then
   cp \$auxfil \$oldaux
  fi
  @< run the three processors @>
done
@| @}

\subsection{Install the service}
\label{sec:installservice}

To install the service on Lisa, the following has to be done:

\begin{enumerate}
\item Generate directories;
\item Unpack the nuweb source;
\item Install the program-manager as a ``cron job''.
\item Make \verb|alpinomanager| executable.
\end{enumerate}

To begin with the third point: Lisa provides the Unix \verb|crontab|
mechanism. In the current installation the author of this program has
installed a crontab that runs a script
\verb|m4_crondriver| every
minute. So, we only have to check whether this script invokes the
process-manages and, if this is not the case, to add a line to the
script.

@d parameters in Makefile @{@%
CRONDRIVER=m4_crondriver
ALPMAN=m4_abindir/alpinomanager 
@| CRONDRIVER @}


@d make targets @{@%
install : m4_progname.w \$(DIRS)
	nuweb -t m4_progname.w
@%	grep -q alpinomanager \$(CRONDRIVER) || echo "\$(ALPMAN)" >>\$(CRONDRIVER)
	cd m4_abindir && chmod 775 alpinomanager
	cd m4_abindir && chmod 775 download_archive
	cd m4_abindir && chmod 775 download
	cd m4_abindir && chmod 775 upload
	cd m4_abindir && chmod 775 filstat
	cd m4_abindir && chmod 775 downloaddir


@| @}
 

\subsection{create the program sources}
\label{sec:createsources}

Run nuweb, but suppress the creation of the \LaTeX{}
documentation. Nuweb creates only sources that do not yet exist or
that have been modified. Therefore make does not have to check this. 



@d make targets @{@%
sources : m4_progname.w
	nuweb -t m4_progname.w
@%@< make executables executable @>

@| @}

Create the directories. Target \verb|DIRS| is a list of the directories 

@d parameters in Makefile @{@%
MKDIR = mkdir -p
@| @}

@d expliciete make regels @{@%

\$(DIRS) :
	\$(MKDIR) \$(DIRS)

@| @}








\section{Indexes}
\label{chap:indexes}


\section{Filenames}
\label{sec:filenames}

@f

\section{Macro's}
\label{sec:macros}

@m

\section{Variables}
\label{sec:veriables}

@u

\end{document}

% Local IspellDict: british 


