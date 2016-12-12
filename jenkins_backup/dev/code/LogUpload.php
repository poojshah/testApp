<?php

	// This controls how much information gets written to the log file.
	// 0 = nothing
	// 1 = normal
	// 2 = debug
	$gVerboseLevel = 2;


	
	function EndsWith($FullStr, $EndStr)
	{
		$endLen = strlen($EndStr);
		$FullStrEnd = substr($FullStr, strlen($FullStr) - $endLen);
		return $FullStrEnd == $EndStr;
	}
	
	
	
	function StartsWith($FullStr, $StartStr)
	{
		$startLen = strlen($StartStr);
		$FullStrStart = substr($FullStr, 0, $startLen);
		return $FullStrStart == $StartStr;
	}


	function WriteToDebugLogFile($logMsg, $thisVerboseLevel) {
		if ($thisVerboseLevel <= $GLOBALS['gVerboseLevel']) {
			$logFile = false;
// switched from m:\WebData/logfiles/installer.nemetschek.net/log_upload_debug.txt on 2013-08-19

			if ($logFile = fopen('../logfiles/log_upload_debug.txt', 'a+t')) {
				fwrite($logFile, $logMsg);
				fclose($logFile);
			}
		}
	}


	function WriteToLogFile($logMsg, $thisVerboseLevel) {
		if ($thisVerboseLevel <= $GLOBALS['gVerboseLevel']) {
			$logFile = false;
// switched from m:\WebData/logfiles/installer.nemetschek.net/log_upload_log.txt on 2013-08-19

			if ($logFile = fopen('../logfiles/log_upload_log.txt', 'a+t')) {
				fwrite($logFile, $logMsg);
				fclose($logFile);
			}
		}
	}


	function WriteToLogFile2($logMsg, $thisVerboseLevel) {
		if ($thisVerboseLevel <= $GLOBALS['gVerboseLevel']) {
			$logFile = false;

			if ($logFile = fopen('../logfiles/log_upload_log2.txt', 'a+t')) {
				fwrite($logFile, $logMsg);
				fclose($logFile);
			}
		}
	}


	function GetIncrementedCount()
	{
		if (true)
			$count = '1';
		else {
		$countFileName = "./filecounter.txt";
		$countFile = fopen($countFileName, 'w');

		// wait until we can get exclusive access to the file
		while (!flock($countFile, LOCK_EX)) {}

		// read, increment, and write
		$count = fread($countFile, filesize($countFileName));
		$count++;
		ftruncate($countFile, 0);
		fwrite($countFile, $count);

		// give up exclusive access to the file
		flock($countFile, LOCK_UN);


		fclose($countFile);
		}
		return $count;
	}



	function GetUniqueFile($rootDir, $datatype)
	{
		$count = 1;

		if ($datatype == "usagelog") {
			$fileNameRoot = "LogFile";
			$fileNameSuffix = ".txt";
		}
		else if ($datatype == "installerlog") {
			$fileNameRoot = "InstallerLogFile";
			$fileNameSuffix = ".txt";
		}
		else if ($datatype == "installersummary") {
			$fileNameRoot = "InstallerSummaryFile";
			$fileNameSuffix = ".txt";
		}
		else if ($datatype == "crashlog") {
			$fileNameRoot = "CrashLogFile";
			$fileNameSuffix = ".txt";
		}
		else if ($datatype == "crashlogwin") {
			$fileNameRoot = "VWCrashDump";
			$fileNameSuffix = ".dmp";
		}
		else {
			$fileNameRoot = "Unknown";
			$fileNameSuffix = ".txt";
		}


		while(file_exists($rootDir.$fileNameRoot.$count.$fileNameSuffix))
			$count += 1;


		return $rootDir.$fileNameRoot.$count.$fileNameSuffix;
	}


function GetPreciseTime()
{
	$mTime = microtime();
	$mTimeX = explode(' ', $mTime);
	return $mTimeX[1] + $mTimeX[0];
}


function Spaces($numberOfThem) {
	$result = '';
	for ($cnt = 0; $cnt < $numberOfThem; $cnt += 1) {
		$result = $result.' ';
	}
	return $result;
}

	date_default_timezone_set('America/New_York');

	$startTime   = GetPreciseTime();
	$dateString  = date('Y-m-d G:i:s', $startTime);
	$ipAddress   = $_SERVER['REMOTE_ADDR'];
	$queryString = $_SERVER['QUERY_STRING'];
	$serverName  = $_SERVER['SERVER_NAME'];
	$queryString = urldecode($queryString);
	$queryString = stripslashes($queryString);



	WriteToDebugLogFile("======================\n", 1);
	WriteToDebugLogFile("date: ".$dateString."\n", 1);
	WriteToDebugLogFile("ip: ".$ipAddress."\n", 1);
	WriteToDebugLogFile("query: ".$queryString."\n", 1);

	//$uploaddir = 'uploads/'; // Relative path under webroot

	// fully specified path to upload data (outside WebSites)- NOT accessible via web
	//$uploadroot = "../../DebugUploads096/";
	//$uploadroot = "m:\WebData/DebugUploads104/";
	//$uploadroot = "n:\WebData/DebugUploads106/";
	
	//2013-11-02
	//$uploadroot = "l:\WebData/DebugUploads107/";

	//$uploadroot = "l:\WebData/DebugUploads108/";

	//$uploadroot = "m:\WebData/DebugUploads109/";
	//$uploadroot = "m:\WebData/DebugUploads110/";
	//$uploadroot = "m:\WebData/DebugUploads111/";


	// time() == number of seconds since the Unix Epoch (January 1 1970 00:00:00 GMT). 

	$t1 = time();
	$t2 = $t1/(3600*24*7);
	$t3 = round($t2);

	$t4 = $t1/(3600*24);
	$t5 = round($t4);

	// this simply makes it match the current index and begin incrementing weeks from here out
	//$folderIndex = $t3-2176;


	// as of directory 128, we are going to daily rotation so the directory size stays smaller
	// because the new linux server has less available space
	
	// we will copy to amazon on a daily basis now
	

	if (false) {


		// this old path collected log files on the local file system
		
		// it was constrained by the space on the local volume and unable to scale out
		// for higher availability


		$folderIndex = $t5-15994;

		//$uploadroot = "m:\WebData/DebugUploads".$folderIndex."/";
		$uploadroot = "../debuguploads/DebugUploads".$folderIndex."/";

		$copyfile = false;

	}
	else {

	
		// preparing to move log root - checking for web sync behavior

		// in order to use this code path, the host running this application needs to have
		// a file system (typically amazon EFS) mounted at /efs
		
		// the /efs/loguploads directory must be set to:

		// chmod 775 loguploads/ 		
		// chown apache:apache loguploads/




	
		$folderIndex = $t5-15993;
		
		
		$uploadroot = "/efs/loguploads/DebugUploads".$folderIndex."/";

		$copyfile = true;

	}


	if (false) {

		WriteToLogFile2(" secs time: ".$t1."\n", 1);
		WriteToLogFile2(" weeks time: ".$t2."\n", 1);
		WriteToLogFile2(" weeks time int: ".$t3."\n", 1);
		WriteToLogFile2(" days time: ".$t4."\n", 1);
		WriteToLogFile2(" days time int: ".$t5."\n", 1);
		WriteToLogFile2(" folder index: ".$folderIndex."\n", 1);

		WriteToLogFile2(" uploadrootauto: ".$uploadrootauto."\n", 1);

		WriteToLogFile2("---\n", 1);
	}

	if (array_key_exists('mac', $_POST))
		$rawmac = strtoupper($_POST['mac']);
	else
		$rawmac = "";
	
	if (array_key_exists('sn', $_POST))
		$rawsn = strtoupper($_POST['sn']);
	else
		$rawsn = "";

	WriteToDebugLogFile("rawmac:".$rawmac."\n", 1);
	WriteToDebugLogFile("rawsn:".$rawsn."\n", 1);

	if (strlen($rawmac) == 17)
		$mac = $rawmac;
	else if(strlen($rawmac) == 27)
		$mac = str_replace(":", "-", urldecode($rawmac));
	else
		$mac = "BAD_MAC";

	if (strlen($rawsn) == 27) {
		$sn = $rawsn;
	}
	else if (strlen($rawsn) == 24 && StartsWith($rawsn, "VWEVAL-")){
		$sn = $rawsn;
	}
	else if (strlen($rawsn) == 17 && StartsWith($rawsn, "EVALUATION-FRALSM")){
		$sn = $rawsn;
	}
	
	else
		$sn = "BAD_SN";

	if (array_key_exists('datatype', $_POST) && strlen($_POST['datatype']) <= 16)
		$datatype = $_POST['datatype'];
	else
		$datatype = "usagelog";


	WriteToDebugLogFile("_POST:".print_r($_POST, true), 1);
	WriteToDebugLogFile("_FILES:".print_r($_FILES, true), 1);


	WriteToDebugLogFile("mac:".$mac."\n", 1);
	WriteToDebugLogFile("sn:".$sn."\n", 1);
	WriteToDebugLogFile("datatype:".$datatype."\n", 1);


//	if (ereg('^[0-9A-F]{2}-[0-9A-F]{2}-[0-9A-F]{2}-[0-9A-F]{2}-[0-9A-F]{2}-[0-9A-F]{2}$', $mac)) {
//		if (ereg('^[0-9A-Z]{6}-[0-9A-Z]{6}-[0-9A-Z]{6}-[0-9A-Z]{6}$', $sn)) {


	$sndir = $uploadroot.$sn."/";
	$uploaddir = $sndir.$mac."/";

	if (!file_exists($uploadroot))
		mkdir($uploadroot);

	if (!file_exists($sndir))
		mkdir($sndir);

	if (!file_exists($uploaddir))
		mkdir($uploaddir);

	$uploadfile = GetUniqueFile($uploaddir, $datatype);

	WriteToDebugLogFile("uploading to: ".$uploadfile."\n", 1);

	WriteToDebugLogFile($_FILES['VWLogData']['tmp_name']."\n", 1);
	WriteToDebugLogFile($_FILES['VWLogData']['name']."\n", 1);
	WriteToDebugLogFile($_FILES['VWLogData']['type']."\n", 1);
	WriteToDebugLogFile($_FILES['VWLogData']['size']."\n", 1);
	WriteToDebugLogFile($_FILES['VWLogData']['error']."\n", 1);

	$logMsg = $ipAddress.Spaces(17 - strlen($ipAddress)).$dateString."\t";
	WriteToLogFile($logMsg, 1);

	WriteToLogFile(" size: ".$_FILES['VWLogData']['size'], 1);
	WriteToLogFile(" file: ".$uploadfile, 1);

	
	if ($copyfile ) {

		$fileToCopy = $_FILES['VWLogData']['tmp_name'];
		if (is_uploaded_file ( $fileToCopy )) {
		
			
			if (copy ( $fileToCopy , $uploadfile)) {
				WriteToDebugLogFile("File is valid, and was successfully copied.\n", 1);
				WriteToLogFile(" SUCCESS", 1);
			
			
				if (unlink ( $fileToCopy )) {
					WriteToDebugLogFile("temp upload file deleted.\n", 1);

								
				}
				else {
					WriteToDebugLogFile("temp upload file - DELETE FAILED.\n", 1);
				
				}
			
			}
			else {
				WriteToDebugLogFile("File uploading failed - copy returned false.\n", 1);
				WriteToLogFile(" FAILURE", 1);
				header('X-PHP-Response-Code: 400', true, 400);
			}
			
		}
		else {
			WriteToDebugLogFile("File uploading failed - is_uploaded_file returned false.\n", 1);
			WriteToLogFile(" FAILURE", 1);
			header('X-PHP-Response-Code: 400', true, 400);
		
		}
	}
	else {	
		if (move_uploaded_file($_FILES['VWLogData']['tmp_name'], $uploadfile)) {
			WriteToDebugLogFile("File is valid, and was successfully uploaded.\n", 1);
			WriteToLogFile(" SUCCESS", 1);
	
		} else {
			WriteToDebugLogFile("File uploading failed.\n", 1);
			WriteToLogFile(" FAILURE", 1);
	
	
			$post_body = file_get_contents('php://input');
	
			$headers = getallheaders();
	
			$t1 = time();
	
			if ($logFile = fopen("../logfiles/post_debug.". $t1 .".txt", 'a+t')) {
	
				foreach ($headers as $header => $value) {
					fwrite($logFile, "$header: $value\n");
				}
	
	
				fwrite($logFile, $post_body);
				fclose($logFile);
			}
	
	
	
			# this is the simplest way in older PHP versions to return a response code
			header('X-PHP-Response-Code: 400', true, 400);
		}
	}
	


	$endTime   = GetPreciseTime();

	$timeTaken = $endTime - $startTime;

	$timeMsg = sprintf("(time: %10.4fs)\n", $timeTaken);

	WriteToLogFile(" ".$timeMsg, 1);
	WriteToDebugLogFile($timeMsg, 1);

?>
