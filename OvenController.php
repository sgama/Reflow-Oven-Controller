<?php
	
	$soak_temp=$_GET["soak_temp"];
	$soak_time=$_GET["soak_time"];
	$reflow_temp=$_GET["reflow_temp"];
	$reflow_time=$_GET["reflow_time"];
	
	echo("<br>");
	echo($_GET["time"]);
	
 
 	// Connects to your Database 
	mysql_connect("localhost", "root") or die(mysql_error()); 
	mysql_select_db("OvenControllerProfiles") or die(mysql_error()); 
	mysql_query("TRUNCATE TABLE profiledata");
	$data = mysql_query("insert into profiledata values($soak_temp,$soak_time,$reflow_temp,$reflow_time)");
	//or die(mysql_error()); 
	echo($data);
?>