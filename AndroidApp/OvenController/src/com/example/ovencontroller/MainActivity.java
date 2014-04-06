package com.example.ovencontroller;

import android.os.Bundle;
import android.app.Activity;
import android.view.Menu;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;

public class MainActivity extends Activity {
	
	Activity mainActivity;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		
		mainActivity=this;
		
		Button submitButton= (Button) findViewById(R.id.submit_button);
		submitButton.setOnClickListener(new View.OnClickListener() {
			
		EditText soakTempText;
		EditText soakTimeText;
		EditText reflowTempText;
		EditText reflowTimeText;
			
			@Override
			public void onClick(View v) {
				soakTempText=(EditText) findViewById(R.id.soak_temp_text);
				soakTimeText=(EditText) findViewById(R.id.soak_time_text);
				reflowTempText=(EditText) findViewById(R.id.reflow_temp_text);
				reflowTimeText=(EditText) findViewById(R.id.reflow_time_text);
				
				new RequestTask().execute(getUrlPost(getIp(), soakTempText.getText().toString(),
						soakTimeText.getText().toString(), reflowTempText.getText().toString(),
						reflowTimeText.getText().toString()));
				new UpdateState(mainActivity).execute(getUrlPoll(getIp()));
			}
		});
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.main, menu);
		return true;
	}
	
	private String getUrlPoll(String ip){
		StringBuilder URL=new StringBuilder();
		URL.append("http://");
		URL.append(ip);
		URL.append("/GetCurrentData.php");
		return URL.toString();
	}
	
	/**
	 * Makes an IP address using the 5 text boxes
	 * Note: The last box (port number) is optional
	 * @return
	 */
	private String getIp(){
		StringBuilder ip=new StringBuilder(20);
		
		EditText ip1=(EditText) findViewById(R.id.ipaddress_text_1);
		EditText ip2=(EditText) findViewById(R.id.ipaddress_text_2);
		EditText ip3=(EditText) findViewById(R.id.ipaddress_text_3);
		EditText ip4=(EditText) findViewById(R.id.ipaddress_text_4);
		EditText ip5=(EditText) findViewById(R.id.ipaddress_text_5);
		
		ip.append(ip1.getText());
		ip.append('.');
		ip.append(ip2.getText());
		ip.append('.');
		ip.append(ip3.getText());
		ip.append('.');
		ip.append(ip4.getText());
		if(!(ip5.getText().toString().equals(""))){
			ip.append(':');
			ip.append(ip5.getText());
		}
		
		return ip.toString();
	}
	
	/**
	 * Makes a URL address to query the PHP file on server using the following params:
	 * @param ip
	 * @param soakTemp
	 * @param soakTime
	 * @param reflowTemp
	 * @param reflowTime
	 * @return
	 */
	public static String getUrlPost(String ip, String soakTemp,String soakTime, String reflowTemp, String reflowTime){
		StringBuilder URL=new StringBuilder();
		URL.append("http://");
		URL.append(ip);
		URL.append("/OvenController.php?soak_temp=");
		URL.append(soakTemp);
		URL.append("&soak_time=");
		URL.append(soakTime);
		URL.append("&reflow_temp=");
		URL.append(reflowTemp);
		URL.append("&reflow_time=");
		URL.append(reflowTime);
		//System.out.println(URL.toString());
		return URL.toString();
		//http://localhost/OvenController.php?soak_temp=23&soak_time=444&reflow_temp=9898&reflow_time=6767
	}

}
