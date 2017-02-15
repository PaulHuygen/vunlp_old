m4_include(inst.m4)m4_dnl
\documentclass[twoside]{artikel3}
\pagestyle{headings}
\usepackage{pdfswitch}
\usepackage{figlatex}
\usepackage{makeidx}
\renewcommand{\indexname}{General index}
\makeindex
\newcommand{\thedoctitle}{m4_doctitle}
\newcommand{\theauthor}{m4_author}
\newcommand{\thesubject}{m4_subject}
\newcommand{\CGI}{\textsc{cgi}}
\newcommand{\CSV}{\textsc{csv}}
@%\newcommand{\HTML}{\textsc{html}}
\newcommand{\HTTP}{\textsc{http}}
\newcommand{\KAF}{\textsc{kaf}}
\newcommand{\PHP}{\textsc{php}}
\newcommand{\VTL}{\textsc{vtl}}
\newcommand{\VU}{\textsc{vu}}
\title{\thedoctitle}
\author{\theauthor}
\date{m4_docdate}
m4_include(texinclusions.m4)m4_dnl
\begin{document}
\maketitle
\begin{abstract}
  This document describes and constructs a front-end for a system on
  supercomputer Lisa that parses documents with a parser like Alpino.
\end{abstract}
\tableofcontents

\section{Introduction}
\label{sec:Introduction}

Some academic research programs use a large quantity of documents as
source-data. Because of the size of the document-set, the documents
must be analysed automatically by computer. This computer-analysis
involves a work-flow that contains resource-intensive ``parsers''.

The VU-university is co-owner of a supercomputer, Lisa, that could be
used for the resource-intensive process-steps.

This document describes part of a system that transports documents to
Lisa in order to have them processed and retrieves the parses. The
advantages of this system are: 1) It hides the complexity of the Lisa
supercomputer for users; 2) Users on the VU can use the computing
power of Lisa without need of a Lisa account and 3) the documents of
multiple users can be polled to use Lisa efficiently.

Processing documents with the described system involves
the following steps:

\begin{enumerate}
\item The user request a unique identifier in order to generate unique filenames.
\item The user constructs a special document. The first line of the
  document contains a sha-bang (\verb|#!|) followed by the
  command-line command to invoke the parser (with the arguments,
  without filenames). The next lines are the lines of the text to be
  parsed, formatted according to the requirements of the parser.
\item The user constructs a file-name that starts with the identifier,
  to ensure that the filename is unique.
\item The user sends the document to the intermediate server.
\item The user can request a list of the processing-states (m4_wait,
  m4_processing, m4_ready) of the
  documents that she sent.
\item The user can download the parses of completed documents.
\end{enumerate}

To enable this, the server has implemented the following four requests:

\begin{tabular}{llll}
 \textbf{request}  & \textbf{argument}  & \textbf{result} & \textbf{Description} \\
 \texttt{getID}    & --       & integer & Get identifier to construct unique filenames (section~\ref{sec:uniqueID}) \\
 \texttt{upload}   & file     & --      & Upload a text (section~\ref{sec:upload})  \\
 \texttt{filstat}  & filename & string  & Check whether a file has been processed (section~\ref{sec:checkstatus}). \\
 \texttt{getparse} & filename  & parse & retrieve a parse (section~\ref{sec:retrieve_parses}) \\
\end{tabular}

This document implements the following:

\begin{itemize}
\item Server 
\item Python module for users 
\item demonstration script in Python 
\item demonstration script in Bash  
\end{itemize}

\section{Example scripts}
\label{sec:examples}

\subsection{Python module and demonstration script}
\label{sec:pythonmodule}

The following script is a Python module that facilitates usage of the
server in Python programs. The module contains a class
\texttt{Vu_Nlpservice} with the following methods:

\begin{tabular}{llll}
 \textbf{method}  & \textbf{arguments}  & \textbf{result} & \textbf{Description} \\
 \texttt{upload\_text} & Alpino command, text, filename & request result & Upload a text for parsing. \\
 \texttt{check\_status} & filename & string & Check status of an uploaded text. \\
 \texttt{retrieve\_parse} & filename & parse & Retrieve the parse. \\
\end{tabular}

@o m4_testdir/vu_nlpservice.py @{@%
#!/usr/bin/python
# vu_nlpservice -- interface to use VU-NLP service to parse texts on Lisa supercomputer
@< imports of vu_nlpservice.py @>
@< http requests in vu_nlpservice.py @>
class VU_nlpservice():
  """
  have texts parsed on Lisa supercomputer
  """

  def __init__(self):
    @< initialise VU_nlpservice class @>

  @< methods in VU_nlpservice class @>

@| @}

@%To demonstrate how it works, the following python script 
@%submits all the files with extension \verb|.txt| in it's own directory
@%and retrieves the parses done by Alpino. Alpino is started
@%with the following command:
@%
@%@d alpinocommand @{@%
@%alpinocommand = 'Alpino assume_input_is_tokenized=off -parse'
@%@| alpinocommand @}

To demonstrate how it works, the following python script submits all
the files with extension \verb|.txt| in it's own directory and
retrieves the parses done by an english-text-to-parsed-KAF utility
written by Ruben Izquierdo. The utility is started with the following
command:

@d rubencommand @{@%
parsecommand='\$NLPROOT/ruben/python/stanford.py'

@| @}

Sorry for the strange nomenclature, mentioning everything ``Alpino''. This utility was originally
developed for Alpino only and now it is extended to use all kind of
processors. Furthermore, sorry fir the strange filepath. That will be
made more general in the future.


@o m4_testdir/vu_nlpservice_demo.py @{@%
#!/usr/bin/python
# vu_nlpservice_demo -- interface to use VU-NLP service to parse texts with Lisa supercomputer
@< imports of vu_nlpservice_demo @>
@%@< alpinocommand @>
@< rubencommand @>
@< get list of text files @>
@< open interface with the server @>
@< submit texts @>
@< poll and download @>
@| @}

@d imports of vu_nlpservice_demo @{@%
import time
@| @}

Make a list of the files in this directory with extension \texttt{.txt}. The texts in these files will be parsed.

@d get list of text files @{@%
import glob
infils = glob.glob('*.txt')
@| @}

Create an VU_nlpservice object to communicate with the server.

@d open interface with the server @{@%
import vu_nlpservice
lisacon = vu_nlpservice.VU_nlpservice()
@| lisacon VU_nlpservice @}

The parse of a text will be stored in a file with the same name as the
input file, but extension \verb|.kaf|. This script considered a text
as parsed when such a file exists. Therefore, we remove such files if
they exist before parsing. 

@d remove file with kaf extension @{@%
import os
outfilnam = @1.replace('.txt', '.kaf')
if os.path.exists(outfilnam):
  os.remove(outfilnam)
@| @}


Submit the texts:

@d submit texts @{@%
@< status trick @>
for infilnam in infils:
   @< remove file with kaf extension @(infilnam@) @>
   @< submit a single text @(infilnam@) @>
@| @}

@d submit a single text @{@%
lisacon.upload_text( parsecommand, @1)
@| upload_text @}


Note a dirty technical trick. When Lisa receives a single input file
and then starts up a job, it will use only one core, even when later
on much more files are submitted. When we first ask for a status,
start-up of jobs is postponed, giving us time upload more
files. Therefore, we start with asking for the status.

@d status trick @{@%
status = lisacon.check_status("aap")
@| @}

When every textfile has been submitted, wait for the parses. Check
every minute whether parses have been completed and download
them. Present a summary of the nuber of retrieved parses and the
number of files waiting on the screen.

Submitted files are in one of the following states:

\begin{description}
\item[m4_ready:] The parse has been downloaded and stored in a file.
\item[m4_processing:] Alpino is currently busy parsing the text.
\item[m4_wait:] The file is waiting in a queue.
\item[m4_unknown:] Somehow the server does not know about the file.
\end{description}

The four variables \verb|readyfils|, \verb|waitingfils|,
\verb|lostfils| and \verb|processedfils| keep track of the number of
files that are in the four states. The script is ready when the values
of \verb|waitingfils|, \verb|lostfils| and \verb|processedfils| are
zero.

@d poll and download @{@%
#
# Poll and download
#
# Download the parses
ready = False
while ( not(ready) ):
 readyfils = 0; waitingfils = 0; lostfils = 0; processedfils = 0
 timeoutfils = 0
 for infilnam in infils:
   @< poll, retrieve if ready and update status @(infilnam@) @>
 @< print a summary @>
 ready = (waitingfils + lostfils + processedfils == 0)
 if (not(ready)):
   time.sleep( 60 )

@| @}

First look whether the parse of a file been retrieved. If this is not
the case, ask the server what the status of the file is (method
\verb|VU_nlpservice.check_status()|). This method returns one of the
strings \verb|m4_ready|, \verb|m4_wait|, \verb|m4_processing| or \verb|m4_unknown|
to indicate the status of a given file.  Retrieve the parse when it is
ready (method \verb|VU_nlpservice.retrieve_parse()|). When a file has
been lost, re-submit it.

@d poll, retrieve if ready and update status @{@%
pfil=@1
outfilnam = pfil.replace('.txt', '.kaf')
if os.path.exists(outfilnam):
   readyfils = readyfils + 1
else:
@%      resp, status = httplib2.Http().request(statusrequest + idfilnam)
   status = lisacon.check_status(pfil)
   if ( 'm4_ready' in status ):
     outfil = open(outfilnam, 'w')
     outfil.write(lisacon.retrieve_parse(pfil))
     outfil.close()
     readyfils = readyfils + 1
   elif 'm4_unknown' in status:
     @< submit a single text @(pfil@) @>
@%     submitfile(id, @1, alpcommand)
     lostfils = lostfils + 1
   elif 'm4_wait' in status:
     waitingfils = waitingfils + 1
   elif 'm4_processing' in status:
     processedfils = processedfils + 1
   elif 'm4_timeout' in status:
     timeoutfils = timeoutfils + 1


@| pfil @}

Print a summary after each poll.

@d print a summary @{@%
print "ready: %4d; processed: %4d; waiting: %4d; lost: %4d; timeout: %4d" % (
         readyfils, processedfils, waitingfils, lostfils, timeoutfils )
@| @}

\subsection{Bash example}
\label{sec:bashexample}

The following bash script does the same as the the python example. It
uses \texttt{curl} to perform the requests to the server.

@o testscript @{@%
#!/bin/bash
@< variables of testscript @>
@< http requests in testscript @>
@< get a unique ID for filenames  with curl @>
echo "ID: " \$ID
@< upload a file @>
@< ask for the state of a file @>
@< download a parse @>
@| @}


\section{The five server requests}
\label{sec:serverrequests}

The requests are sent to the url of the server: In the python script:

@d http requests in vu_nlpservice.py @{@%
serverurl = 'm4_projrootURL/index.php'
@| serverurl @}

In Bash:

@d http requests in testscript @{@%
SERVERURL=m4_projrootURL/index.php
@| SERVERURL @}

\subsection{The unique identifier}
\label{sec:uniqueID}

The user prepends filenames of her documents with a unique
identifier. In this way she can take care by herself that the
documents have unique filenames and cannot be confused with files from
other users. The following form constructs a request for a unique
identifier.

@d form to request a unique identifier @{@%
<form action="m4_projrootURL/index.php" method="get">
    <input type="submit" name="getID" value="getID">
</form>
@| @}


The request is issued with the following \HTTP{} request:
\verb|m4_projrootURL/index.php?getID|.



@d get a unique ID for filenames with curl @{@%
@%ID=`curl -s "m4_projrootURL/index.php?getID=getID"`
ID=`curl -s "\$SERVERURL?getID=getID"`
@| @}

In Python it goes as follows:

@d initialise VU_nlpservice class @{@%
IDrequest=serverurl + "?getID"
resp, self.id = httplib2.Http().request(IDrequest)
self.id = self.id.replace("\n", "")
@| @}


@%@d python method to get a unique ID for filenames @{@%
@%def getid():
@%  resp, id = httplib2.Http().request(IDrequest)
@%  id = id.replace("\n", "")
@%  return id
@%@| @}

We need to import \verb|httplib2| for this:

@d imports of vu_nlpservice.py @{@%
import httplib2
@| httplib2 @}

The \textsc{id} is a four-digit number. Assuming that the number of
ID's in use in a couple of hours, this should be sufficient. Store the
ID in a file.

@%@o m4_projroot/ID @{@%
@%0
@%@| @}

Note that the \HTTP{} server must be able to rewrite this file.

Processing the request for an \textsc{id} involves 1) Read the number
in the ID-file (set this number to zero if the ID-file does not
exist); 2) increment the number in the ID-file modulo m4_maxid and 3)
write the number to output.

@d process the request for an ID @{@%
@%if(htmlspecialchars(\$_GET["getID"])=="getID"){
if(array_key_exists("getID", \$_GET )){
  @< read and update the content of the ID file @>
  @< write the ID @>
};
@| @}

@d read and update the content of the ID file @{@%
\$ID=file_get_contents('m4_aprojroot/ID');
if(\$ID===FALSE){
  \$ID=0;
};
@< write variable to new file @(\$ID+1@,"m4_aprojroot/ID"@) @>
@| @}

@d write the ID @{@%
printf("%04d\n", \$ID);
@%printf("<html><head></head><body><p>ID=%04d</p></html>\n", \$ID);
@| @}


\subsection{Upload a file}
\label{sec:upload}

Uploading a file involves for the user 1) to create a file that can be parsed and
that contains the parser-command and 2) upload that file. A suitable
form to enable the user to upload a file would be:

@d form to upload a file @{@%
<form action="m4_projrootURL/index.php" method="post" enc-type="multipart/form-data">
  <input type="file" name="infil" >
  <input type="submit" name="upload" value="upload"> 
</form>
@| @}

A client could use this form, e.g.{} with a curl script as follows:

@d upload the testfile @{@%
curl -s --form infil=@@@1 --form upload=upload "\$SERVERURL"
@| @}

In the python module the request is made as followa 

As mentioned in section~\ref{sec:Introduction}, the file to be
uploaded has to begin with the Alpino command, followed by the text to
be parsed. To be precise, the first line of the upload consists of a
``sha-bang'' followed by the alpino-command. So, the user has to
construct such a file. Let us assume that the user only wants a simple
parse of text in file \verb|testtext.sts|: 

@d variables of testscript @{@%
ALPINOCOMMAND='#!Alpino -parse'
@| @}

@o testtext.sts @{@%
Dat is nog niet duidelijk . 
We zien hier niet het breken van tandenstokers .
Dodelijke wapens worden gesloopt . 
Slechts enkele nieuwe documenten zijn aan het licht gekomen . 
Er is nog geen bewijs van verboden activiteiten gevonden .
@| @}

The testscript concatenates the the two file into a single one,
prepends the name with the \textsc{id} and uploads it.

@d upload a file @{@%
TESTFILENAME=testtext.sts
UTESTFILENAME=\$ID"."\$TESTFILENAME
@%cat alpino_command \$TESTFILENAME >\$UTESTFILENAME
echo ALPINOCOMMAND >\$UTESTFILENAME
cat \$TESTFILENAME >>\$UTESTFILENAME
@< upload the testfile @(\$UTESTFILENAME@) @>
rm \$UTESTFILENAME
@| @}


The python library proceeds as follows:

@d methods in VU_nlpservice class  @{@%
def upload_text(self, parsecommand, filnam):
  idfilnam =  self.id + filnam
  files = {'infil': (idfilnam, '#!' + parsecommand + '\n' + open(filnam, 'r').read())}
@%  r = requests.post(m4_projrootURL/index.php, files=files)
  r = requests.post(serverurl, files=files)
  return r

@| @}

@d imports of vu_nlpservice.py @{@%
import requests
@| requests @}


@%The server processes the uploaded file. It sends the file with
@%\textsc{ssh} to a command in Lisa that receives the file. This should
@%be done with the \textsc{ssh} facilities in \textsc{php} but I am too
@%dumb to do that.

The server puts the uploaded file in the intray.

@d process a file upload @{@%
if(array_key_exists('infil', \$_FILES)){
  \$uploaddir = 'm4_aintraypath';
  \$uploadfile = \$uploaddir . '/' . basename(\$_FILES['infil']['name']);
  \$result=move_uploaded_file(\$_FILES['infil']['tmp_name'], \$uploadfile);
  if(\$result){
    printf("waiting\n");
  }else{
    printf("lost\n");
  };
}

@%@%if($_FILES['infil']['size']>0){
@%if(array_key_exists('infil', \$_FILES)){
@%  \$filename=\$_FILES['infil']['name'];
@%  \$tmpinname=\$_FILES['infil']['tmp_name'];
@%  @%shell_exec("SSH user@host.com mkdir /testing");
@%@%  \$result=shell_exec("cat <\$tmpinname | m4_sshcommand \"m4_lisa_download_command \$filename\"");
@%
@%};
@| @}


\subsection{Check status of files}
\label{sec:checkstatus}

The client may check the status of a file that she has sent. There are
four possible states: ``m4_wait'', ``m4_processing'', ``m4_ready'',
``m4_unknown''.  Furthermore, there will be a web page in which the user
can see the status of every file that she has sent.

The status of a file can be retrieved with the following form:

@d form to check the status of a file @{@%
<form action="m4_projrootURL/index.php" method="get">
  <input type="text" name="filnam">
  <input type="submit" name="filstat" value="status">
</form>
@| @}

The curl script to retrieve the status will then be:

@d ask status of file @{@%
FILSTAT=`curl -s "m4_projrootURL/index.php?filstat=status&filnam=@1"`
@| FILSTAT @}

In python it works as follows:

@d http requests in vu_nlpservice.py @{@%
statusrequest=serverurl + "?filstat=status&filnam="
@| statusrequest @}


@d methods in VU_nlpservice class @{@%
def check_status(self, filnam):
  idfilnam = self.id + filnam
  resp, status = httplib2.Http().request(statusrequest + idfilnam)
  return status

@| @}



Let us process this request. If the user supplied a filename, get the
state from Lisa, put it in variable \verb|\$filstat| and write it
out. Otherwise, write state "m4_unknown".

@d process the request for file-state @{@%
if(array_key_exists("filstat", \$_GET )){
  if(!array_key_exists("filnam", \$_GET )){
    \$filstat="m4_unknown";
  } else { 
    \$filename=\$_GET['filnam'];
    @< get the state of ``filename'' @>
@%    @< get the state from Lisa of @(\$_GET['filnam']@,\$filstat@) @>
  };
  @< write the state @(\$filstat@) @>
};
@| @}

Lisa sends at regular intervals reports of the files being
processed. The report is printed in file \verb|m4_astatusrep|. Do as
follows:

\begin{enumerate}
\item Check whether the parse is present in the outtray. If that is
  the case, report state ``m4_ready''.
\item If that is not the case, check whether the file is still in the
  intray, waiting to be moved to Lisa. In that case, report state ``m4_wait''.
@%\item If that is not the case, check whether the the list of files
@%  from Lisa is obsolete. If that is the case, request a new file. The
@%  request returns the state of the file.
\item Get the status from the statusreport from Lisa.
\item report the status.
\end{enumerate}

@d get the state of ``filename''@{@%
\$filstat="false";
@< find out whether the file is in tray @(outtray@,m4_ready@) @>
if(\$filstat=="false"){
  @< find out whether the file is in tray @(intray@,m4_wait@) @>
};
@%if(\$filstat=="false"){
@%  @< get the state from lisa when the statusfile is obsolete @>
@%};
if(\$filstat=="false"){
  @< get the status from the statusfile @>
};
if(\$filstat=="false") \$filstat="m4_unknown";
@| @}

Check whether the file is still in the intray or already in the
outtray. The first argument of the following macro is the name of the
tray and the second argument is the state that belongs to that tray.

@d find out whether the file is in tray @{@%
@%\$outfil="m4_aouttraypath" . "/" . \$filename;
\$outfil="m4_aprojroot" . "/@1/" . \$filename;
if(file_exists(\$outfil)){
  \$filstat="@2";
};
@| @}


@%@d get the state from lisa when the statusfile is obsolete @{@%
@%\$statusfile = 'm4_statusrep';
@%\$max_lifetime=120;
@%if (!file_exists(\$statusfile) or (time - filemtime(\$statusfile) >= \$max_lifetime)) {
@%    @< request new statusfile and get status @>
@%};
@%@| @}

@%@d request new statusfile and get status @{@%
@%\$command="m4_lisa_staterequest_command " . \$filename;
@%@%@2=shell_exec("m4_sshcommand \"m4_lisa_staterequest_command @1\"");
@%\$filstat=shell_exec("m4_sshcommand \"".\$command."\"");
@%@| @}


If the statusfile is not obsolete, read from it until the filename has been found. The
statefile is a text file with one word per line. Each line contains
either the name of a ``tray'' in which files can reside, or the name
of a file. The trays can be ``intray:'', ``proctray:'' or
``outttray:''. The intray contains the files that are waiting to be
processed, the proctray contains the files that are being processed
and the outtray contains the processed files.

Not that the files in the outtray of Lisa are not yet accessible for
download to a client. Therefore, files in that list must be labeled as
``being processed''.

@d get the status from the statusfile @{@%
\$statusfile = 'm4_statusrep';
\$handle=fopen(\$statusfile, 'r');
\$bufstat="m4_unknown";
while((\$buffer = fgets(\$handle, 4096)) !== false){
  @< process status label @(intray:@,m4_wait@) @>
  @< process status label @(proctray:@,m4_processing@) @>
  @< process status label @(outtray:@,m4_processing@) @>
  @< process status label @(toootray:@,m4_timeout@) @>
  @< process filename @>
};
fclose(\$handle);
@| @}


@d process status label @{@%
if(preg_match("/^@1/", \$buffer)==1){
  \$bufstat="@2";
  continue;
}
@| @}

@d process filename @{@%
if(preg_match("/^" . $filename . "/", $buffer)==1){
  \$filstat=\$bufstat;
  break;
}
@| @}


@%@d get the state from Lisa of @{@%
@%\$command="m4_lisa_staterequest_command " . @1;
@%@%@2=shell_exec("m4_sshcommand \"m4_lisa_staterequest_command @1\"");
@%@2=shell_exec("m4_sshcommand \"".\$command."\"");
@%@| @}

@d write the state @{@%
printf("%s\n", @1);
@| @}




In the testscript we are going to ask for the state of the file that we have sent. 

@d ask for the state of a file @{@%
@< ask status of file @(\$UTESTFILENAME@) @>
echo File state: \$FILSTAT;
@| @}

\subsection{Retrieve parses}
\label{sec:retrieve_parses}

To retrieve the parse of an input-file, the user could fill in a form
like the following:

@d form to retrieve a parse @{@%
<form action="m4_projrootURL/index.php" method="get">
  <input type="text" name="filnam">
  <input type="submit" name="getparse" value="getparse">
</form>
@| @}


The curl script to print the retrieved file will then be:

@d print parse of @{@%
echo `curl -s "m4_projrootURL/index.php?getparse=getparse&filnam=@1"` >@1
@| PARSE @}

In the python library:

@d http requests in vu_nlpservice.py @{@%
retrieverequest = serverurl + '?getparse=getparse&filnam='
@| retrieverequest @}

@d methods in VU_nlpservice class @{@%
def retrieve_parse(self, filnam):
  idfilnam =  self.id + filnam
  resp, outfilcontent = httplib2.Http().request(retrieverequest + idfilnam)
  if outfilcontent == "notfound\n" :
    raise BaseException('Could not retrieve ' + filnam)
  return outfilcontent

@| retrieve_parse @}

Note, that the above method assumes that, in response to this request,
the server sends the file or it sends the word "notfound".

@d  process the request for a parse @{@%
if(array_key_exists("getparse", \$_GET )){
  if(!array_key_exists("filnam", \$_GET )){
    printf("notfound\n");
@%    \$filstat="unknown";
  } else { 
    \$filename= "m4_aouttraypath" . "/" . \$_GET['filnam'];
    if(file_exists(\$filename)){
      @< print file @(\$filename@) @>
      @< remove file @(\$filename@) @>
@%    @< print the file as obtained from Lisa @(\$_GET['filnam']@)@>
    } else {
      printf("notfound\n");
    };
  };
};

@| @}


Print the file in the argument. Note that opening and reading a file
using \textsc{php}'s \texttt{fopen()} instruction and the
\textsc{feof()} test can lead to an infinite loop and an enormous
logfile that takes up all the free discspace of the server. The
\texttt{fopen()} instruction returns either a file handle or the
boolean \textsc{false}. In the latter case, \texttt{feof()} will
print error messages tot the log file, but never return
\texttt{true}. Therefore, if \texttt{fopen()} returns \texttt{false},
just print \texttt{notfound}.

@d print file @{@%
\$handle=fopen(@1, 'r');
if(\$handle===FALSE){
  printf("notfound\n");
}else{
  \$bufsize=10000;
  while(!feof(\$handle)){
    print fread(\$handle, \$bufsize);
  }
};
fclose(\$handle);
@| @}

Remove a file:

@d remove file @{@%
unlink(@1);
@| unlink @}



@%@d print the file as obtained from Lisa @{@%
@%\$command="m4_lisa_parserequest_command " . @1;
@%@%\$command="echo poep ";
@%@%@2=shell_exec("m4_sshcommand \"m4_lisa_staterequest_command @1\"");
@%@%printf("Retrieve file: %s\n", @1);
@%@%printf("%s", shell_exec("m4_sshcommand \"".\$command."\""));
@%@%printf("%s\n", shell_exec("m4_sshcommand \"".$command."\""));
@%print(shell_exec("m4_sshcommand \"".\$command."\""));
@%@| @}

The testfile downloads a parse:

@d download a parse @{@%
@< print parse of @(test01.sts.alp@) @>
@| @}

\subsection{Upload a directory with software}
\label{sec:uploaddir}

Users can install a directory with their own scripts and programs and
use these to process their texts. It works as follows: The user
creates a directory tree with her own name as the root directory. In
this directory she puts scripts and executables. Next, she packs the
directory tree into a ``gzipped'' tar file. Then, she uploads the
directory, with her own name as argument. If all goes well, the
directory will be unpacked in Lisa as subdirectory of \texttt{m4_lisa_projroot}.

@d form to upload a directory @{@%
<form action="m4_projrootURL/uploaddir.php" method="post" enc-type="multipart/form-data">
  <label for="file">Tarball:</label>
  <input type="file" name="file" id="file"><br>
  <label for="user">Username:</label>
  <input type="text" name="root" ><br>
  <input type="submit" name="submit" value="submit"> 
</form>
@| @}

Process this form in a separate \PHP{} file, because this upload is intended
to be performed manually by the user.

@o uploaddir.php @{@%
<html>
<head>
</head>
<body>
<?php
@< process the request to upload a directory @>
?>
@< form to upload a directory @>
</body>
</html>
@| @}

Don't forget to install the \PHP{} script (put it in its place)

@d expliciete make regels @{@%
@< install a php file @(\$(WEBDIR)/uploaddir@,uploaddir@) @>
@| @}


@d process the request to upload a directory @{@%
@%if(array_key_exists('file', \$_FILES)){
if (\$_FILES["file"]["error"] > 0){
  printf("<p>No tarball found.</p>\n");
}else{
  \$tarball=\$_FILES["file"]["tmp_name"];
  \$rootname=\$_POST['root'];
  \$result = shell_exec("m4_sshcommand \"m4_lisa_downloaddir_command " . \$rootname . "\"  <\$tarball");
  if(\$result == NULL){
    printf("<p>Could not upload to Lisa</p>\n");
  } else{
    printf("Result: %s\n", \$result);
  };
};

@| @}

@%@d receive the tarball @{@%
@%@%  \$uploaddir = 'm4_aintraypath';
@%@%  \$uploadfile = \$uploaddir . '/' . basename(\$_FILES['tarball']['name']);
@%  \$uploadfile = tempnam("/tmp", "tarbaldir");
@%  unlink(\$uploadfile);
@%  \$result=move_uploaded_file(\$_FILES['file']['tmp_name'], \$uploadfile);
@%@| @}
@%
@%@d remove the tarball @{@%
@%unlink(\$uploadfile);
@%@| @}
@%
@%@d receive the name of the rootdir @{@%
@%@%\$rootname=\$_GET['root'];
@%\$rootname=\$_POST['root'];
@%@| @}
@%
@%
@%@d upload the tarball to Lisa @{@%
@%\$result = shell_exec("m4_sshcommand \"m4_lisa_downloaddir_command " . \$rootname . "\"  <\$uploadfile");
@%printf("Result: %s\n", \$result);
@%@| @}
@%


\section{Operations}
\label{sec:operations}

\subsection{Bookkeeping of texts}
\label{sec:userreg}

When the service is actually processing files, connection with the
Lisa server is needed at regular intervals. However, when there are no
clients, it is not necessary to repeatedly contact the server.




\section{Overview of the scripts}
\label{sec:overview}

\subsection{Script that processes user requests}
\label{sec:userprocessscript}

The interface functions are implemented in a single \textsc{php}
script. The script processes \textsc{http} requests and displays forms
that can be used interactively.

The script is located in a directory that makes it accessible for the
\HTML{} server. Currently the \URL{} for the interface-server is
\verb|m4_projurl| and the directory that belongs to this \URL{}
is \verb|m4_httproot|.

@o index.php @{@%
<?php
  @< run pseudocron @>
  @< process requests @>
?>
@| @}

Put the script in its proper place:

@d expliciete make regels @{@%
@< install a php file @(\$(WEBDIR)@,index@) @>
@%\$(WEBDIR)/index.php : m4_progname<!!>.w
@%	\${NUWEB} m4_progname<!!>.w
@%	mv index.php \$(WEBDIR)

@| @}

The script processes the following requests:

\begin{itemize}
\item A request to get and \textsc{id}. With the \textsc{id} a user
  can generate unique filenames that cannot be generated by other
  users. This is needed because the files of all users will be pooled.
\item Upload of a file that contains the text to be parsed.
\item Request for information about the status of an upload. It tells
  the user whether the file is still waiting, being processed or
  ready.
\item Request to download a parse.
\end{itemize}

@d process requests @{@%
@< process the request for an ID @>
@< process a file upload @>
@< process the request for file-state @>
@< process the request for a parse @>
@| @}

It is possible (mainly for testing purposes) to submit requests manually with forms.

@o forms @{@%
  @< html header @(Forms for Alpino interface@) @>
  @< form to request a unique identifier @>
  @< form to upload a file @>
  @< form to check the status of a file @>
  @< form to retrieve a parse @>
@%@< html tail @>
@| @}


There is a Python library to help python users. It is used in the
example of the previous section.



There is a demo script for Python. Put this script in a directory
together with files that contain Dutch plain text and that have
filenames that end with \verb|.txt|. When the user runs the
demo-script and all goes will, she will eventually get a file with the
parse for each of the text files.



The scripts issue requests to the \URL{} that belongs to this script,
i.e. \verb|m4_projrootURL/index.php|.

@d http requests in vu_nlpservice.py @{@%
serverurl = 'm4_projrootURL/index.php'
@| serverurl @}

@d http requests in testscript @{@%
SERVERURL=m4_projrootURL/index.php
@| SERVERURL @}

\subsection{Cron script}
\label{sec:cronscript}

@%The actual communication with Lisa is performed with a script that is
@%executed at regular intervals

Communicate periodically with Lisa, to send files from the intray, to
get files from the outtray and to get a list of files.

@d run pseudocron @{@%
\$indicatorfile="m4_userrequest_indicatorfile";
if (file_exists(\$indicatorfile)) {
  \$runcron=(time()-fileatime(\$indicatorfile) >= m4_max_nocron_period);
} else {
  \$runcron=(1==1);
};
if(\$runcron){
  shell_exec("m4_abindir/cronscript");
  \$result=touch(\$indicatorfile);
};
@| @}

@o m4_projroot/bin/cronscript @{@%
#!/bin/bash
@%@< stop when no user-requests have been received@>
@< upload new texts @>
@< download parses @>
@< request filelist @>
@| @}

@%@d stop when no user-requests have been received @{@%
@%@< check whether update is necessary @(m4_userrequest_indicatorfile@,m4_max_nouser_period@,GOIDLE@) @>
@%if \$GOIDLE
@%then
@%  exit
@%fi
@%@| @}

@d upload new texts @{@%
if [ "\$(ls -A m4_aintraypath)" ]
then
@%  \$result=shell_exec("cat <\$tmpinname | m4_sshcommand \"m4_lisa_download_command \$filename\"");
 OLDD=`pwd`
 cd m4_aintraypath
 tar czf - * | m4_sshcommand "m4_lisa_download_archive_command \$filename"
 rm *
fi
@| @}


@%@d check whether update is necessary  @{@%
@%@%@< write log @(now: `date +%s`@) @>
@%@%arg=@1
@%@%stamp=`date -r @1 +%s`
@%@%@< write log @($arg: $stamp@) @>
@%@%passeer
@%if [ ! -e @1 ]
@%then
@%  @3=true
@%elif [ \$((`date +%s` - `date -r @1 +%s`)) -gt @2 ]
@%then
@%  @3=true
@%else
@%  @3=false
@%fi
@%@| @}

Request a list with the state of the uploaded texts. The script seems
to expect some text, so give it something with the \verb|yes| script.

@d request filelist @{@%
yes | m4_sshcommand "m4_lisa_staterequest_command \"aap\"" > m4_astatusrep
@%\$command="m4_lisa_staterequest_command " . \$filename;
@%@2=shell_exec("m4_sshcommand \"m4_lisa_staterequest_command @1\"");
@%\$filstat=shell_exec("m4_sshcommand \"".\$command."\"");
@| @}
 
@d download parses @{@%
@%rsync -avz --remove-source-files %phuijgen@@lisa.sara.nl:alpino/outtray m4_aprojroot/
rsync -avz --remove-source-files  phuijgen@@lisa.sara.nl:m4_lisa_outtray m4_aprojroot/
@| @}


\subsection{HTML environment}
\label{sec:html}

Build the header of the \textsc{html} script with style
instructions. This is all stolen from pipet
(\url{m4_pipetURL}).

@d html header @{@%
m4_changequote(<!`!>,<!'!>)m4_dnl
<!xml version="1.0" encoding="UTF-8">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
m4_changequote(`<!',`!>')m4_dnl
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <title>@1</title>
  @< html style @>
</head>
@| @}


@d html style @{@%
<style type="text/css">
  body { background-color: #f4f4ff; }
  h1 { color: #444; }
  a { color: #44a; text-decoration: none; }
  a:hover { color: #4a4; }
  dt, label { color: #944; font-weight: bold; }
  input.button { background-color: #fff4f4; color: #944; border: 1px solid #944; }
  .poweredBy { font-size: small; }
</style>
@| @}



\section{Basic operations}
\label{sec:basicops}

@d write variable to new file @{@%
\$handle=fopen(@2, "w");
\$result=fwrite(\$handle, @1);
\$result=fclose(\$handle);
@| @}


@%\section{Miscellaneous}
@%\label{sec:miscellaneous}
@%
@%@d  html head @{@%
@%<?xml version="1.0" encoding="UTF-8"?>
@%<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
@%           "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
@%>
@%<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
@%<head>
@%  <title>
@%    @1
@%  </title>
@%</head>
@%@| @}
@%
@%@d html tail @{@%
@%</body>
@%</html>
@%@| @}


\appendix

\section{How to read and translate this document}
\label{sec:translatedoc}

This document is an example of \emph{literate
  programming}~\cite{Knuth:1983:LP}. It contains the code of all sorts
of scripts and programs, combined with explaining texts. In this
document the literate programming tool \texttt{nuweb} is used, that is
currently available from Sourceforge
(URL:\url{m4_nuwebURL}). The advantages of Nuweb are, that
it can be used for every programming language and scripting language, that
it can contain multiple program sources and that it is very simple.


\subsection{Read this document}
\label{sec:read}

The document contains \emph{code scraps} that are collected into
output files. An output file (e.g. \texttt{output.fil}) shows up in the text as follows:

\begin{alltt}
"output.fil" \textrm{4a \(\equiv\)}
      # output.fil
      \textrm{\(<\) a macro 4b \(>\)}
      \textrm{\(<\) another macro 4c \(>\)}
      \(\diamond\)

\end{alltt}

The above construction contains text for the file. It is labelled with
a code (in this case 4a)  The constructions between the \(<\) and
\(>\) brackets are macro's, placeholders for texts that can be found
in other places of the document. The test for a macro is found in
constructions that look like:

\begin{alltt}
\textrm{\(<\) a macro 4b \(>\) \(\equiv\)}
     This is a scrap of code inside the macro.
     It is concatenated with other scraps inside the
     macro. The concatenated scraps replace
     the invocation of the macro.

{\footnotesize\textrm Macro defined by 4b, 87e}
{\footnotesize\textrm Macro referenced in 4a}
\end{alltt}

Macro's can be defined on different places. They can contain other macro´s.

\begin{alltt}
\textrm{\(<\) a scrap 87e \(>\) \(\equiv\)}
     This is another scrap in the macro. It is
     concatenated to the text of scrap 4b.
     This scrap contains another macro:
     \textrm{\(<\) another macro 45b \(>\)}

{\footnotesize\textrm Macro defined by 4b, 87e}
{\footnotesize\textrm Macro referenced in 4a}
\end{alltt}


\subsection{Process the document}
\label{sec:processing}

The raw document is named
\verb|a_<!!>m4_progname<!!>.w|. @%Figure~\ref{fig:fileschema}
@%\begin{figure}[hbtp]
@%  \centering
@%  \includegraphics{fileschema.fig}
@%  \caption{Translation of the raw code of this document into
@%    printable/viewable documents and into program sources. The figure
@%    shows the pathways and the main files involved.}
@%  \label{fig:fileschema}
@%\end{figure}
@% shows pathways to
@%translate it into printable/viewable documents and to extract the
@%program sources. Table~\ref{tab:transtools}
@%\begin{table}[hbtp]
@%  \centering
@%  \begin{tabular}{lll}
@%    \textbf{Tool} & \textbf{Source} & \textbf{Description} \\
@%    gawk  & \url{www.gnu.org/software/gawk/}& text-processing scripting language \\
@%    M4    & \url{www.gnu.org/software/m4/}& Gnu macro processor \\
@%    nuweb & \url{nuweb.sourceforge.net} & Literate programming tool \\
@%    tex   & \url{www.ctan.org} & Typesetting system \\
@%    tex4ht & \url{www.ctan.org} & Convert \TeX{} documents into \texttt{xml}/\texttt{html}
@%  \end{tabular}
@%  \caption{Tools to translate this document into readable code and to
@%    extract the program sources}
@%  \label{tab:transtools}
@%\end{table}
@%lists the tools that are
@%needed for a translation. Most of the tools (except Nuweb) are available on a
@%well-equipped Linux system.
@%
@%\textbf{NOTE:} Currently, not the most recent version  of Nuweb is used, but an older version that has been modified by me, Paul Huygen.
@%
@%@d parameters in Makefile @{@%
@%NUWEB=m4_nuwebbinary
@%@| @}


\subsection{Translate and run}
\label{sec:transrun}

This chapter assembles the Makefile for this project.

@o Makefile -t @{@%
@%@< default target @>
@< parameters in Makefile @> 
@< impliciete make regels @>
@< expliciete make regels @>
@< make targets @>
@| @}

To begin with, the contents of the nuweb source must be unpacked and
placed in the proper directories. To start simple, we put everything
in a single directory. Unpacking involves the following steps:

\begin{enumerate}
\item Transform \verb|a_<!!>m4_progname| into another file,
  \verb|m4_<!!>m4_progname|, in which \verb|\\$| sequences have been
  replaced by \verb|\$| characters and comments (i.e.{} an
  \verb|@@<!!>%| character sequence, the remainder of the text-line
  including the end-of-line character) have been removed.
\item Run the m4
  preprocessor\footnote{\url{http://www.gnu.org/software/m4/}} on
  \verb|`m4_'m4_progname| to obtain \verb|m4_progname|.
\item Unpack \verb|m4_progname| with nuweb.
\end{enumerate}

The first step:

@d expliciete make regels @{@%
m4_<!!>m4_progname<!!>.w : a_<!!>m4_progname<!!>.w
@%	gawk '/^@@%/ {next}; {gsub(/[\\][\\$\$]/, "$$");print}' a_<!!>m4_progname<!!>.w > m4_<!!>m4_progname<!!>.w
	gawk '{if(match($$0, "@@<!!>%")) {printf("%s", substr($$0,1,RSTART-1))} else print}' a_<!!>m4_progname.w \
          | gawk '{gsub(/[\\][\\$\$]/, "$$");print}'  > m4_<!!>m4_progname<!!>.w
@% $

@| @}


The second step:

@d  expliciete make regels @{@%
m4_progname<!!>.w : m4_<!!>m4_progname<!!>.w
	m4 -P m4_<!!>m4_progname<!!>.w > m4_progname<!!>.w

@| @}

The third step involves using the Nuweb program. Nuweb takes care
of dependencies by itself.

@d parameters in Makefile @{@%
NUWEB=m4_nuwebbinary
@| NUWEB @}

Currently, installing the software involves to unpack the nuweb
source and move it into its proper location. This has to be done in
two separate steps because later versions of Nuweb prepend the paths of
outputfiles with \verb|.\|.

@d parameters in Makefile @{@%
WEBDIR=m4_httproot
@| @}



@%@d make targets @{@%
@%install : m4_progname<!!>.w inst.m4
@%	\${NUWEB} m4_progname<!!>.w
@%	mv index.php m4_httproot
@%
@%@| @}


@d install a php file @{@%
@1/@2.php : m4_progname<!!>.w
	\${NUWEB} m4_progname<!!>.w
	mv @2.php @1

@| @}



@d make targets @{@%
install : \$(WEBDIR)/index.php \$(WEBDIR)/uploaddir/uploaddir.php
	\${NUWEB} m4_progname<!!>.w
	mv index.php m4_httproot
	chmod 775 m4_abindir/cronscript
@%	chown :www-data m4_projroot/ID

@| @}

To test the software, install it and run the testscript.

@d make targets @{@%
test : m4_progname<!!>.w inst.m4
	\${NUWEB} m4_progname<!!>.w
	chmod 775 ./testscript
	./testscript

@| @}

We use many suffixes that were not known by the C-programmers who
constructed the \texttt{make} utility. Add these suffixes to the list.

@d parameters in Makefile @{@%
.SUFFIXES: .pdf .w .tex .html .aux .log .php

@| SUFFIXES @}

\subsection{Print the document}
\label{sec:print}

To print this document, unpack it, convert it into \textsc|pdf| and
print. Conversion to  \textsc|pdf| involves multiple steps with
\LaTeX{} and nuweb. This is performed with the \verb|w2pdf| script,
that can be obtained from \url{m4_w2pdfurl}:

@d expliciete make regels @{@%
w2pdf :
	wget m4_w2pdfurl
	chmod 775 ./w2pdf

@| @}

Use the script to generate \textsc{pdf}

@d  impliciete make regels@{@%
@%.w.pdf :   <== Does not seem to work.
%.pdf : %.w w2pdf  \$(PDF_FIG_NAMES) \$(PDFT_NAMES)
	./w2pdf \$*

@| @}


@d make targets @{@%

pdf : m4_progname.pdf

print : m4_progname.pdf
	lpr m4_progname.pdf

@| @}

\subsection{Render as HTML}
\label{sec:html}

Render the document as \HTML{} in a subdirectory.

@d parameters in Makefile @{@%
HTMLDOCDIR=m4_aprojroot/nuweb/html
@| HTMLDOCDIR @}


@d make targets @{@%
\$(HTMLDOCDIR) :
	mkdir \$(HTMLDOCDIR)

html : \$(HTMLDOCDIR) m4_progname.w 
	cp m4_progname.w \$(HTMLDOCDIR)/m4_progname.nw
	cd \$(HTMLDOCDIR) && w2html m4_progname.nw

@| @}





@%\subsection{The w2pdf script}
@%\label{sec:w2pdf}
@%
@%The three processors nuweb, \LaTeX{} and bib\TeX{} are
@%intertwined. \LaTeX{} and bib\TeX{} create parameters or change the
@%value of parameters, and write them in an auxiliary file. The other
@%processors may need those values to produce the correct output. The
@%\LaTeX{} processor may even need the parameters in a second
@%run. Therefore, consider the creation of the (\pdf) document finished
@%when none of the processors causes the auxiliary file to change. This
@%is performed by a shell script \verb|w2pdf|
@%
@%@o w2pdf @{@%
@%#!/bin/bash
@%# w2pdf -- convert a nuweb file into PDF
@%`#' m4_header
@%NUWEB=m4_nuwebbinary
@%LATEXCOMPILER=pdflatex
@%
@%@| @}
@%


@%\subsection{Pre-processing}
@%\label{sec:pre-processing}
@%
@%To make usable things from the raw input \verb|a_<!!>m4_progname<!!>.w|, do the following:
@%
@%\begin{enumerate}
@%\item Process \verb|\$| characters.
@%\item Run the m4 pre-processor.
@%\item Run nuweb.
@%\end{enumerate}
@%
@%This results in a \LaTeX{} file, that can be converted into a \pdf{}
@%or a \HTML{} document, and in the program sources and scripts.
@%
@%\subsubsection{Process `dollar' characters }
@%\label{sec:procdollars}
@%
@%Many ``intelligent'' \TeX{} editors (e.g.\ the auctex utility of
@%Emacs) handle \verb|\$| characters as special, to switch into
@%mathematics mode. This is irritating in program texts, that often
@%contain \verb|\$| characters as well. Therefore, we make a stub, that
@%translates the two-character sequence \verb|\\$| into the single
@%\verb|\$| character.
@%
@%
@%
@%@%@d expliciete make regels @{@%
@%@%m4_<!!>m4_progname<!!>.w : a_<!!>m4_progname<!!>.w
@%@%	gawk '/^@@%/ {next}; {gsub(/[\\][\\$\$]/, "$$");print}' a_<!!>m4_progname<!!>.w > m4_<!!>m4_progname<!!>.w
@%@%
@%@%@% $
@%@%@| @}
@%
@%Run the M4 pre-processor:
@%
@%@d  expliciete make regels @{@%
@%m4_progname<!!>.w : m4_<!!>m4_progname<!!>.w
@%	m4 -P m4_<!!>m4_progname<!!>.w > m4_progname<!!>.w
@%
@%@| @}
@%
@%\subsection{Typeset this document}
@%\label{sec:typeset}
@%
@%Enable the following:
@%\begin{enumerate}
@%\item Create a \pdf{} document.
@%\item Print the typeset document.
@%\item View the typeset document with a viewer.
@%\item Create a \HTML document.
@%\end{enumerate}
@%
@%In the three items, a typeset \pdf{} document is required or it is the
@%requirement itself.
@%
@%
@%\subsubsection{Figures}
@%\label{sec:figures}
@%
@%This document contains figures that have been made by
@%\texttt{xfig}. Post-process the figures to enable inclusion in this
@%document.
@%
@%The list of figures to be included:
@%
@%@d parameters in Makefile @{@%
@%FIGFILES=fileschema
@%
@%@| FIGFILES @}
@%
@%We use the package \texttt{figlatex} to include the pictures. This
@%package expects two files with extensions \verb|.pdftex| and
@%\verb|.pdftex_t| for \texttt{pdflatex} and two files with extensions \verb|.pstex| and
@%\verb|.pstex_t| for the \texttt{latex}/\texttt{dvips}
@%combination. Probably tex4ht uses the latter two formats too.
@%
@%Make lists of the graphical files that have to be present for
@%latex/pdflatex:
@%
@%@d parameters in Makefile @{@%
@%FIGFILENAMES=\$(foreach fil,\$(FIGFILES), \$(fil).fig)
@%PDFT_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pdftex_t)
@%PDF_FIG_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pdftex)
@%PST_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pstex_t)
@%PS_FIG_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pstex)
@%
@%@|FIGFILENAMES PDFT_NAMES PDF_FIG_NAMES PST_NAMES PS_FIG_NAMES@}
@%
@%
@%Create
@%the graph files with program \verb|fig2dev|:
@%
@%@d impliciete make regels @{@%
@%%.eps: %.fig
@%	fig2dev -L eps \$< > \$@@
@%
@%%.pstex: %.fig
@%	fig2dev -L pstex \$< > \$@@
@%
@%.PRECIOUS : %.pstex
@%%.pstex_t: %.fig %.pstex
@%	fig2dev -L pstex_t -p \$*.pstex \$< > \$@@
@%
@%%.pdftex: %.fig
@%	fig2dev -L pdftex \$< > \$@@
@%
@%.PRECIOUS : %.pdftex
@%%.pdftex_t: %.fig %.pstex
@%	fig2dev -L pdftex_t -p \$*.pdftex \$< > \$@@
@%
@%@| fig2dev @}


\paragraph{Bibliography}
\label{sec:bbliography}

To keep this document portable, create a portable bibliography
file. It works as follows: This document refers in the
\texttt|bibliography| statement to the local \verb|bib|-file
\verb|m4_progname.bib|. To create this file, copy the auxiliary file
to another file \verb|auxfil.aux|, but replace the argument of the
command \verb|\bibdata{m4_progname}| to the names of the bibliography
files that contain the actual references (they should exist on the
computer on which you try this). This procedure should only be
performed on the computer of the author. Therefore, it is dependent of
a binary file on his computer.


@d expliciete make regels @{@%
bibfile : m4_progname.aux m4_mkportbib
	m4_mkportbib m4_progname m4_bibliographies

.PHONY : bibfile
@| @}

@%\subsubsection{Create a printable/viewable document}
@%\label{sec:createpdf}
@%
@%Make a \pdf{} document for printing and viewing.
@%
@%@d make targets @{@%
@%pdf : m4_progname.pdf
@%
@%print : m4_progname.pdf
@%	m4_printpdf(m4_progname)
@%
@%view : m4_progname.pdf
@%	m4_viewpdf(m4_progname)
@%
@%@| pdf view print @}
@%
@%Create the \pdf{} document. This may involve multiple runs of nuweb,
@%the \LaTeX{} processor and the bib\TeX{} processor, and depends on the
@%state of the \verb|aux| file that the \LaTeX{} processor creates as a
@%by-product. Therefore, this is performed in a separate script,
@%\verb|w2pdf|.
@%
@%\paragraph{The w2pdf script}
@%\label{sec:w2pdf}
@%
@%
@%Note, that in the following \texttt{make} construct, the implicit rule
@%\verb|.w.pdf| is not used. It turned out, that make did not calculate
@%the dependencies correctly when I did use this rule.
@%
@%
@%The following is an ugly fix of an unsolved problem. Currently I
@%develop this thing, while it resides on a remote computer that is
@%connected via the \verb|sshfs| filesystem. On my home computer I
@%cannot run executables on this system, but on my work-computer I
@%can. Therefore, place the following script on a local directory.
@%
@%@d parameters in Makefile @{@%
@%W2PDF=m4_abindir/w2pdf
@%@| @}
@%
@%@%@d expliciete make regels  @{@%
@%@%\$(W2PDF) : m4_progname.w
@%@%	\$(NUWEB) m4_progname.w
@%@| @}
@%
@%m4_dnl
@%m4_dnl Open compile file.
@%m4_dnl args: 1) directory; 2) file; 3) Latex compiler
@%m4_dnl
@%m4_define(m4_opencompilfil,
@%`@o '\$1<!!>\$2` @{@%
@%#!/bin/bash
@%# '\$2` -- compile a nuweb file
@%# usage: '\$2` [filename]
@%# 'm4_header`
@%NUWEB=m4_nuwebbinary
@%LATEXCOMPILER='\$3`
@%@< filenames in nuweb compile script @>
@%@< compile nuweb @>
@%
@%@| @}
@%')m4_dnl
@%
@%m4_opencompilfil(`m4_bindir/',`w2pdf',`pdflatex')m4_dnl

@%@o w2pdf @{@%
@%#!/bin/bash
@%# w2pdf -- make a pdf file from a nuweb file
@%# usage: w2pdf [filename]
@%#  [filename]: Name of the nuweb source file.
@%`#' m4_header
@%echo "translate " \$1 >w2pdf.log
@%@< filenames in w2pdf @>
@%
@%@< perform the task of w2pdf @>
@%
@%@| @}
@%
@%The script retains a copy of the latest version of the auxiliary file.
@%Then it runs the four processors nuweb, \LaTeX{}, MakeIndex and bib\TeX{}, until
@%they do not change the auxiliary file or the index. 
@%
@%@d compile nuweb @{@%
@%NUWEB=m4_nuweb
@%@< run the processors until the aux file remains unchanged @>
@%@< remove the copy of the aux file @>
@%@| @}
@%
@%The user provides the name of the nuweb file as argument. Strip the
@%extension (e.g.\ \verb|.w|) from the filename and create the names of
@%the \LaTeX{} file (ends with \verb|.tex|), the auxiliary file (ends
@%with \verb|.aux|) and the copy of the auxiliary file (add \verb|old.|
@%as a prefix to the auxiliary filename).
@%
@%@d filenames in nuweb compile script @{@%
@%nufil=\$1
@%trunk=\${1%%.*}
@%texfil=\${trunk}.tex
@%auxfil=\${trunk}.aux
@%oldaux=old.\${trunk}.aux
@%indexfil=\${trunk}.idx
@%oldindexfil=old.\${trunk}.idx
@%@| nufil trunk texfil auxfil oldaux indexfil oldindexfil @}
@%
@%Remove the old copy if it is no longer needed.
@%@d remove the copy of the aux file @{@%
@%rm \$oldaux
@%@| @}
@%
@%Run the three processors. Do not use the option \verb|-o| (to suppres
@%generation of program sources) for nuweb,  because \verb|w2pdf| must
@%be kept up to date as well.
@%
@%@d run the three processors @{@%
@%\$NUWEB \$nufil
@%\$LATEXCOMPILER \$texfil
@%makeindex \$trunk
@%bibtex \$trunk
@%@| nuweb makeindex bibtex @}
@%
@%
@%Repeat to copy the auxiliary file and the index file  and run the processors until the
@%auxiliary file and the index file are equal to their copies.
@% However, since I have not yet been able to test the \verb|aux|
@%file and the \verb|idx| in the same test statement, currently only the
@%\verb|aux| file is tested.
@%
@%It turns out, that sometimes a strange loop occurs in which the
@%\verb|aux| file will keep to change. Therefore, with a counter we
@%prevent the loop to occur more than m4_maxtexloops times.
@%
@%@d run the processors until the aux file remains unchanged @{@%
@%LOOPCOUNTER=0
@%while
@%  ! cmp -s \$auxfil \$oldaux 
@%do
@%  if [ -e \$auxfil ]
@%  then
@%   cp \$auxfil \$oldaux
@%  fi
@%  if [ -e \$indexfil ]
@%  then
@%   cp \$indexfil \$oldindexfil
@%  fi
@%  @< run the three processors @>
@%  if [ \$LOOPCOUNTER -ge 10 ]
@%  then
@%    cp \$auxfil \$oldaux
@%  fi;
@%done
@%@| @}


@%\subsubsection{Create HTML files}
@%\label{sec:createhtml}
@%
@%\textsc{Html} is easier to read on-line than a \pdf{} document that
@%was made for printing. We use \verb|tex4ht| to generate \HTML{}
@%code. An advantage of this system is, that we can include figures
@%in the same way as we do for \verb|pdflatex|.
@%
@%Nuweb creates a \LaTeX{} file that is suitable
@%for \verb|latex2html| if the source file has \verb|.hw| as suffix instead of
@%\verb|.w|. However, this feature is not compatible with tex4ht.
@%
@%Make html file:
@%
@%@d make targets @{@%
@%html : m4_htmltarget
@%
@%@| @}
@%
@%The \HTML{} file depends on its source file and the graphics files.
@%
@%Make lists of the graphics files and copy them.
@%
@%@d parameters in Makefile @{@%
@%HTML_PS_FIG_NAMES=\$(foreach fil,\$(FIGFILES), m4_htmldocdir/\$(fil).pstex)
@%HTML_PST_NAMES=\$(foreach fil,\$(FIGFILES), m4_htmldocdir/\$(fil).pstex_t)
@%@| @}
@%
@%
@%@d impliciete make regels @{@%
@%m4_htmldocdir/%.pstex : %.pstex
@%	cp  \$< \$@@
@%
@%m4_htmldocdir/%.pstex_t : %.pstex_t
@%	cp  \$< \$@@
@%
@%@| @}
@%
@%Copy the nuweb file into the html directory.
@%
@%@d expliciete make regels @{@%
@%m4_htmlsource : m4_progname.w
@%	cp  m4_progname.w m4_htmlsource
@%
@%@| @}
@%
@%We also need a file with the same name as the documentstyle and suffix
@%\verb|.4ht|. Just copy the file \verb|report.4ht| from the tex4ht
@%distribution. Currently this seems to work.
@%
@%@d expliciete make regels @{@%
@%m4_4htfildest : m4_4htfilsource
@%	cp m4_4htfilsource m4_4htfildest
@%
@%@| @}
@%
@%Copy the bibliography.
@%
@%@d expliciete make regels  @{@%
@%m4_htmlbibfil : m4_anuwebdir/m4_progname.bib
@%	cp m4_anuwebdir/m4_progname.bib m4_htmlbibfil
@%
@%@| @}
@%
@%
@%
@%Make a dvi file with \texttt{w2html} and then run
@%\texttt{htlatex}. 
@%
@%@d expliciete make regels @{@%
@%m4_htmltarget : m4_htmlsource m4_4htfildest \$(HTML_PS_FIG_NAMES) \$(HTML_PST_NAMES) m4_htmlbibfil
@%	cp w2html m4_abindir
@%	cd m4_abindir && chmod 775 w2html
@%	cd m4_htmldocdir && m4_abindir/w2html m4_progname.w
@%
@%@| @}
@%
@%Create a script that performs the translation.
@%
@%@%m4_<!!>opencompilfil(m4_htmldocdir/,`w2dvi',`latex')m4_dnl
@%
@%
@%@o w2html @{@%
@%#!/bin/bash
@%# w2html -- make a html file from a nuweb file
@%# usage: w2html [filename]
@%#  [filename]: Name of the nuweb source file.
@%`#' m4_header
@%echo "translate " \$1 >w2html.log
@%NUWEB=m4_nuwebbinary
@%@< filenames in w2html @>
@%
@%@< perform the task of w2html @>
@%
@%@| @}
@%
@%The script is very much like the \verb|w2pdf| script, but at this
@%moment I have still difficulties to compile the source smoothly into
@%\textsc{html} and that is why I make a separate file and do not
@%recycle parts from the other file. However, the file works similar.
@%
@%
@%@d perform the task of w2html @{@%
@%@< run the html processors until the aux file remains unchanged @>
@%@< remove the copy of the aux file @>
@%@| @}
@%
@%
@%The user provides the name of the nuweb file as argument. Strip the
@%extension (e.g.\ \verb|.w|) from the filename and create the names of
@%the \LaTeX{} file (ends with \verb|.tex|), the auxiliary file (ends
@%with \verb|.aux|) and the copy of the auxiliary file (add \verb|old.|
@%as a prefix to the auxiliary filename).
@%
@%@d filenames in w2html @{@%
@%nufil=\$1
@%trunk=\${1%%.*}
@%texfil=\${trunk}.tex
@%auxfil=\${trunk}.aux
@%oldaux=old.\${trunk}.aux
@%indexfil=\${trunk}.idx
@%oldindexfil=old.\${trunk}.idx
@%@| nufil trunk texfil auxfil oldaux @}
@%
@%@d run the html processors until the aux file remains unchanged @{@%
@%while
@%  ! cmp -s \$auxfil \$oldaux 
@%do
@%  if [ -e \$auxfil ]
@%  then
@%   cp \$auxfil \$oldaux
@%  fi
@%@%  if [ -e \$indexfil ]
@%@%  then
@%@%   cp \$indexfil \$oldindexfil
@%@%  fi
@%  @< run the html processors @>
@%done
@%@< run tex4ht @>
@%
@%@| @}
@%
@%
@%To work for \textsc{html}, nuweb \emph{must} be run with the \verb|-n|
@%option, because there are no page numbers.
@%
@%@d run the html processors @{@%
@%\$NUWEB -o -n \$nufil
@%latex \$texfil
@%makeindex \$trunk
@%bibtex \$trunk
@%htlatex \$trunk
@%@| @}
@%
@%
@%When the compilation has been satisfied, run makeindex in a special
@%way, run bibtex again (I don't know why this is necessary) and then run htlatex another time.
@%@d run tex4ht @{@%
@%m4_index4ht
@%makeindex -o \$trunk.ind \$trunk.4dx
@%bibtex \$trunk
@%htlatex \$trunk
@%@| @}
@%

@%\paragraph{create the program sources}
@%\label{sec:createsources}
@%
@%Run nuweb, but suppress the creation of the \LaTeX{} documentation.
@%Nuweb creates only sources that do not yet exist or that have been
@%modified. Therefore make does not have to check this. However,
@%\qstring{make} has to create the directories for the sources if they
@%do not yet exist.
@%@%This is especially important for the directories
@%@%with the \HTML{} files. It seems to be easiest to do this with a shell
@%@%script.
@%So, let's create the directories first.
@%
@%@d parameters in Makefile @{@%
@%MKDIR = mkdir -p
@%
@%@| MKDIR @}
@%
@%
@%
@%@d make targets @{@%
@%DIRS = @< directories to create @>
@%
@%\$(DIRS) : 
@%	\$(MKDIR) \$@@
@%
@%@| DIRS @}
@%
@%
@%@d make targets @{@%
@%sources : m4_progname.w \$(DIRS)
@%@%	cp ./createdirs m4_bindir/createdirs
@%@%	cd m4_bindir && chmod 775 createdirs
@%@%	m4_bindir/createdirs
@%	\$(NUWEB) m4_progname.w
@%
@%jetty : sources
@%	cd .. && mvn jetty:run
@%
@%@| @}

@%@o createdirs @{@%
@%#/bin/bash
@%# createdirs -- create directories
@%`#' m4_header
@%@< create directories @>
@%@| @}


\section{References}
\label{sec:references}

\subsection{Literature}
\label{sec:literature}

\bibliographystyle{plain}
\bibliography{m4_progname}

\subsection{URL's}
\label{sec:urls}

\begin{description}
\item[Nuweb:] \url{m4_nuwebURL}
\end{description}

\section{Indexes}
\label{sec:indexes}


\subsection{Filenames}
\label{sec:filenames}

@f

\subsection{Macro's}
\label{sec:macros}

@m

\subsection{Variables}
\label{sec:veriables}

@u

\end{document}

% Local IspellDict: british 

% LocalWords:  Webcom
