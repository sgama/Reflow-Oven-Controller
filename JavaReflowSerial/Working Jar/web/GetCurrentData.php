<?php
	
	$db = new PDO("sqlite:web/reflowdb.db");
	$data = $db->prepare("SELECT * FROM CURRENTDATA WHERE ID=1");
	
	$data->execute();
	$current_temp = $data->fetchColumn(1);
	$data->execute();
	$current_state = $data->fetchColumn(2);
	$data->execute();
	$current_time = $data->fetchColumn(3);

	echo $current_temp . "|" ;
	echo $current_time . "|" ;
	echo $current_state . "|" ;

	
?>