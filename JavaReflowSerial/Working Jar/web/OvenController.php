<?php
	
	$soak_temp=$_GET["soak_temp"];
	$soak_time=$_GET["soak_time"];
	$reflow_temp=$_GET["reflow_temp"];
	$reflow_time=$_GET["reflow_time"];
	
	echo("<br>");
	echo($_GET["time"]);
	
	$db = new PDO("sqlite:web/reflowdb.db");
	$data = $db->query("update profiledata set soak_temp=$soak_temp, soak_time=$soak_time, reflow_temp=$reflow_temp, reflow_time=$reflow_time where id=1"); 
	echo($data);
?>