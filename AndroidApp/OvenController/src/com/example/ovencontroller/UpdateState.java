package com.example.ovencontroller;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.StatusLine;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;

import android.app.Activity;
import android.os.AsyncTask;
import android.widget.TextView;

public class UpdateState extends AsyncTask<String, String, String>{

	Activity mainActivity;
	
	String phpUrl;
    
    int currentTemp;
    int currentTime;
    String currentState;
    
    Runnable updateTextBoxes;
    
    public UpdateState(Activity activity){
    	mainActivity=activity;
    	/*
    	TextView currentTempText=(TextView) mainActivity.findViewById(R.id.currentTempText);
    	TextView currentTimeText=(TextView) mainActivity.findViewById(R.id.currentTimeText);
    	TextView currentStateText=(TextView) mainActivity.findViewById(R.id.currentStateText);
    	*/
    	updateTextBoxes=new Runnable(){
    		TextView currentTempText=(TextView) mainActivity.findViewById(R.id.currentTempText);
        	TextView currentTimeText=(TextView) mainActivity.findViewById(R.id.currentTimeText);
        	TextView currentStateText=(TextView) mainActivity.findViewById(R.id.currentStateText);
    		
    		@Override
    		public void run(){
    			currentTempText.setText(Integer.toString(currentTemp));
    			currentTimeText.setText(Integer.toString(currentTime));
    			currentStateText.setText(currentState);
    		}
    	};
    }
    
    /*
    TextView currentTempText;
	TextView currentTimeText;
	TextView currentStateText;
    public void updateTextBoxes(){
    	currentTempText.setText(currentTemp);
		currentTimeText.setText(currentTime);
		currentStateText.setText(currentState);
    }*/
    
    public String makeRequest(){
    	HttpClient httpclient = new DefaultHttpClient();
        HttpResponse response;
        String responseString = null;
        try {
            response = httpclient.execute(new HttpGet(phpUrl));
            System.out.println(phpUrl);
            StatusLine statusLine = response.getStatusLine();
            if(statusLine.getStatusCode() == HttpStatus.SC_OK){
                ByteArrayOutputStream out = new ByteArrayOutputStream();
                response.getEntity().writeTo(out);
                out.close();
                responseString = out.toString();
            } else{
                //Closes the connection.
                response.getEntity().getContent().close();
                throw new IOException(statusLine.getReasonPhrase());
            }
        } catch (ClientProtocolException e) {
            //TODO Handle problems..
        } catch (IOException e) {
            //TODO Handle problems..
        }
        return responseString;
    }
    
    /**
     * Queries the PHP file and gets the current data
     * Assumes the following format:
     * 130|440|2|
     * temp|time|state_code|
     */
    public void updateCurrentFields(){
    	String phpResponse=makeRequest();
    	int[] pipes=new int[3];
    	int pipeCount=0;
    	int i,l=phpResponse.length();
    	for(i=0; i<l; i++){
    		if(phpResponse.charAt(i)=='|'){
    			pipes[pipeCount]=i;
    			pipeCount++;
    		}
    	}
    	currentTemp=Integer.parseInt(phpResponse.substring(0, pipes[0]));
    	currentTime=Integer.parseInt(phpResponse.substring(pipes[0]+1, pipes[1]));
    	int currentStateCode=Integer.parseInt(phpResponse.substring(pipes[1]+1, pipes[2]));
    	
    	if(currentStateCode==0){
    		currentState="Waiting for Inputs";
    	}
    	else if(currentStateCode==1){
    		currentState="Ramping to Soak";
    	}
    	else if(currentStateCode==2){
    		currentState="Soaking";
    	}
		else if(currentStateCode==3){
			currentState="Ramping to Reflow";
	   	}
		else if(currentStateCode==4){
			currentState="Reflowing";
		}
		else if(currentStateCode==5){
			currentState="Cooling Down";
		}
    }
    
	@Override
    protected String doInBackground(String... uri) {
        phpUrl=uri[0];
        
        while(true){
        	updateCurrentFields();
        	System.out.println(currentTemp);
        	System.out.println(currentTime);
        	System.out.println(currentState);
        	mainActivity.runOnUiThread(updateTextBoxes);
        	//updateTextBoxes();
        	try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
        }
    	
    }
}