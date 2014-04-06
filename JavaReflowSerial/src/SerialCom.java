import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import javafx.*;

import j.extensions.comm.SerialComm;

public class SerialCom {
		/*
		 * Which ComPort to use: For me, its 3 on OSX (with a driver), and 0 on windows
		 */
        public static final int COMPORT = 2;


        public static void main(String[] args) {
                final SerialComm com = SerialCom.initCom(COMPORT);
                InputStream ComStream = com.getInputStream();
                OutputStream comOut = com.getOutputStream();
                try{
                        while(true){
                        String dbdata="";
                        int[] dbints = ReflowDatabase.readDB(1);
                        for(int i=0; i<dbints.length; i++){
                        	dbdata=dbdata+dbints[i]+' ';
                        }
                        SerialCom.sendString(comOut, "122 122 122 122");
                        System.out.print(readTemp(ComStream));
                        }
                } catch (IOException e) {
                        // TODO Auto-generated catch block
                        e.printStackTrace();
                }
               


                
        }
        
        public static String readTemp( InputStream com) throws IOException {
                String string = "";
                int currentRead = com.read();
                
                while (currentRead!='\r' && currentRead!='\n'){
                        string = string + (char)currentRead;
                        currentRead = com.read();
                }
                if (string.equals(""))return string;
                string = string + '\n'; 
                return string;
        }

        public static int[] getTemp(InputStream com){
                String temp="";
                int [] data = new int[2];
                try {
                        temp = readTemp(com);
                } catch (IOException e) {
                        // TODO Auto-generated catch block
                        e.printStackTrace();
                }
                while (temp.length()!=5){
                        try {
                                temp = readTemp(com);
                        } catch (IOException e) {
                                // TODO Auto-generated catch block
                                e.printStackTrace();
                        }
                }
                data[0] = Integer.parseInt(temp.substring(0,3));
                data[1] = Integer.parseInt(temp.substring(3,4));
                
                return data;
        }
        
        public static SerialComm initCom(int port){
                SerialComm[] ComPorts = SerialComm.getCommPorts();
                for (int i=0; i<ComPorts.length; i++){
                        System.out.println(ComPorts[i].getSystemPortName());
                        System.out.println(ComPorts[i].getDescriptivePortName());
                        System.out.println();
                }
                
                ComPorts[port].setComPortParameters(115200,8, SerialComm.TWO_STOP_BITS, SerialComm.NO_PARITY);
                
                ComPorts[port].openPort();
                return ComPorts[port];
        }
        
        
        public static void sendString (OutputStream com, String string) throws IOException{
        	char[] chars = string.toCharArray();
        	int i=0;
        	com.write(' ');
        	while (i<chars.length){
        		com.write((Character)chars[i]);
        		i++;
        	}
        	if (chars.length<16){
        		for (int j=0; j<(16-chars.length); j++){
        			com.write(' ');
        		}
        	}
        	com.write('\n');
        }

}