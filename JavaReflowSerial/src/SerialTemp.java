import j.extensions.comm.SerialComm;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.LinkedList;

import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.webapp.WebAppContext;

import javafx.event.ActionEvent;
import javafx.event.Event;
import javafx.event.EventHandler;
import javafx.geometry.Pos;
import javafx.geometry.VPos;
import javafx.scene.Node;
import javafx.scene.Scene;
import javafx.scene.chart.LineChart;
import javafx.scene.chart.NumberAxis;
import javafx.scene.chart.XYChart;
import javafx.scene.control.*;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Pane;
import javafx.scene.layout.Region;
import javafx.scene.layout.StackPane;
import javafx.scene.layout.VBox;
import javafx.scene.text.Font;
import javafx.scene.text.FontWeight;
import javafx.animation.*;
import javafx.application.Application;
import javafx.application.Platform;
import javafx.stage.Stage;
import javafx.stage.WindowEvent;
import javafx.util.Duration;
public class SerialTemp extends Application{

	private int[] data;
	private int temp;
	private int state;
	private int time;
	private volatile boolean running;
	private LinkedList<Integer> capturedData = new LinkedList<Integer>();
	private Label tempDisplay = new Label();
	private Label ipDisplay = new Label();
	private Timeline timeline;
	private XYChart.Series<Number, Number> series;
	private SerialComm com;
	private InputStream comIn;
	private OutputStream comOut;
	private NumberAxis xAxis;
    private NumberAxis yAxis;
    private int xrange = 240;
    private int yrange = 255;
    private int[] dbints;
    private VBox settings = new VBox();
	private HBox header = new HBox();
	private HBox chartcontrols = new HBox();
	private HBox datacontrols = new HBox();
	private Button startbtn = new Button();
	private Button stopbtn = new Button();
	private Button settingsbtn = new Button();
	private BorderPane content = new BorderPane();
	private Button chart_control_submit = new Button();
	private Button export_btn = new Button();
	private Button reset_capture = new Button();
	private TextField x_control_box = new TextField();
	private TextField y_control_box = new TextField();
	private Label x_control_label = new Label();
	private Label y_control_label = new Label();
	private Label chart_control_label = new Label();
	private StackPane root = new StackPane();
	private StackPane controls = new StackPane();
	private LineChart<Number,Number> lineChart;
	private Stage comStage;
	private Scene mainScene;
	
	
	public static void main(String[] args) {
		launch(args);
	}
	
	@Override
	public void start(Stage primaryStage) {
		running = true;
		time = 0;
		final Server reflowServer = initServer();
		startCom();
	
		
		new Thread(){
			public void run() {
				try {
					reflowServer.start();
					reflowServer.join();
				} catch (Exception e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
				System.out.println("Server thread has exited");
			}
		 }.start();
		 
		new Thread(){
				public void run() {
					while(running){
						String dbdata="";
	                    int[] dbints = ReflowDatabase.readDB(1);
	                    int i=0;
	                    while(i<dbints.length){
	                    	if (dbints[i]<100){
	                    		dbdata=dbdata+0+dbints[i]+' ';
	                    	}
	                    	else {
	                    		dbdata=dbdata+dbints[i]+' ';
	                    	}
	                    	i++;
	                    }
						try {
							SerialCom.sendString(comOut, dbdata);
							data = SerialCom.getTemp(comIn);
							temp=data[0];
							state=data[1];
						} catch (IOException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
					}
					System.out.println("Serial Communication thread has exited");
				}
		}.start();
	
		primaryStage.setTitle("Temperature/Time Chart");
		stopbtn.setVisible(false);
		startbtn.setText("Start Temperature Capture");
		startbtn.setId("start_btn");
		stopbtn.setText("Stop Temperature Capture");
		stopbtn.setId("stop_btn");
		startbtn.setOnAction(new EventHandler<ActionEvent>(){	
			@Override
			public void handle(ActionEvent event) {
				startbtn.setVisible(false);
				stopbtn.setVisible(true);
				stateTempDisplay();
				timeline = new Timeline();
				timeline.setCycleCount(Timeline.INDEFINITE);
				timeline.getKeyFrames().add(
						new KeyFrame(Duration.seconds(1),
								new EventHandler<ActionEvent>(){
								 @Override
								 public void handle(ActionEvent event) {
									 stateTempDisplay();
									 capturedData.add(temp);
									 time++;
									 series.getData().add(new XYChart.Data<Number, Number>(time,temp));
									 ReflowDatabase.updateCurrentData(temp, state, time);
									 if(time>xAxis.getUpperBound()+1){
										 xAxis.setUpperBound(xAxis.getUpperBound()+1);
										 xAxis.setLowerBound(xAxis.getLowerBound()+1);
									 }
									 
								 }
						}));
				timeline.playFromStart();
				
				
				
			}
		});
		
		stopbtn.setOnAction(new EventHandler<ActionEvent>(){
			@Override
			public void handle(ActionEvent event){
				stopbtn.setVisible(false);
				startbtn.setVisible(true);
				tempDisplay.setText("");
				startbtn.setText("Resume Temperature Capture");
				timeline.stop();
			}
		});
		
		
		primaryStage.setOnCloseRequest(new EventHandler<WindowEvent>() {

            @Override
            public void handle(WindowEvent t) {
            	try {
					reflowServer.stop();
				} catch (Exception e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
                running = false;
                System.exit(0);
            }

        });
		
		header.setSpacing(10);
		header.setAlignment(Pos.CENTER);
		header.setPrefHeight(60);
		header.setId("header");
		
		
		xAxis = new NumberAxis("Time", 1, xrange, 1);
        yAxis = new NumberAxis("Temperature(C)", 0, yrange, 5);
        //creating the chart
        lineChart = new LineChart<Number,Number>(xAxis,yAxis);             
        lineChart.setTitle("Temperature/Time Chart");
        lineChart.setAnimated(true);
        lineChart.setLegendVisible(false);
        lineChart.setCreateSymbols(false);
        //defining a series
        series = new XYChart.Series<Number, Number>();
        series.setName("Serial Temperature");
        //populating the series with data
        lineChart.getData().add(series);
        
        series.getData().add(new XYChart.Data<Number, Number>(time,temp));
        
	content.setTop(header);
	content.setCenter(lineChart);
		
	root.getChildren().add(content);
	header.getChildren().addAll(controls, tempDisplay, ipDisplay, settingsbtn);
	controls.getChildren().addAll(startbtn, stopbtn);
	SettingsPane();
	mainScene = new Scene(root, 1000, 800);
	mainScene.getStylesheets().add("styleMain.css");
	primaryStage.setScene(mainScene);
	primaryStage.show();
	}
	
	private void SettingsPane(){
		settingsbtn.setText("Settings");
		settingsbtn.setOnAction(new EventHandler<ActionEvent>(){
			@Override
			public void handle(ActionEvent event){
				Node prev_view = content.getCenter();
				if (prev_view!=settings){
					content.setCenter(settings);
				}
				else {
					content.setCenter(lineChart);
				}
			}
		});
		datacontrols.getChildren().addAll(reset_capture, export_btn);
		datacontrols.setId("data_controls");
		datacontrols.setSpacing(10);
		reset_capture.setText("Reset Temperature Capture");
		reset_capture.setOnAction(new EventHandler<ActionEvent>(){
			@Override
			public void handle(ActionEvent event){
				stopbtn.setVisible(false);
				startbtn.setVisible(true);
				startbtn.setText("Start Temperature Capture");
				tempDisplay.setText("");
				timeline.stop();
				capturedData.clear();
				time=0;
				xAxis.setUpperBound(xrange);
				xAxis.setLowerBound(0);
				series.getData().clear();
			}
		});
		export_btn.setText("Export Data");
		export_btn.setOnAction(new EventHandler<ActionEvent>(){
			@Override
			public void handle(ActionEvent event){
				try {
					exportData(capturedData);
				} catch (FileNotFoundException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				} catch (UnsupportedEncodingException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		});
		
		
		try {
			ipDisplay.setText("IP Address: "+InetAddress.getLocalHost().getHostAddress());
		} catch (UnknownHostException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
		ipDisplay.setId("IP_display");
		chartcontrols.getChildren().addAll(chart_control_label, y_control_label, y_control_box, x_control_label, x_control_box, chart_control_submit );
		chartcontrols.setId("chartcontrols");
		chartcontrols.setSpacing(10);
		y_control_label.setText("Temp range:");
		x_control_label.setText("Time range:");
		y_control_box.setText(""+yrange);
		x_control_box.setText(""+xrange);
		chart_control_submit.setText("Set");
		chart_control_label.setText("Chart Settings:");
		chart_control_label.setId("chart_control_label");
		chart_control_submit.setOnAction(new EventHandler<ActionEvent>(){
			@Override
			public void handle(ActionEvent event){
				int xrange_old = xrange;
				yrange=Integer.parseInt(y_control_box.getText());
				xrange=Integer.parseInt(x_control_box.getText());
				yAxis.setUpperBound(yrange);
				if (time>xrange_old && xrange>time){
					xAxis.setLowerBound(1);
					xAxis.setUpperBound(xrange);
				}
				else if (xrange>time) xAxis.setUpperBound(xAxis.getUpperBound()+(xrange-xrange_old));
				else{
					xAxis.setUpperBound(time);
					xAxis.setLowerBound(time-xrange);
				}
			}
		});
		settings.getChildren().addAll(datacontrols, ipDisplay, chartcontrols);
		settings.setId("settings");
	}
	
	private void stateTempDisplay(){
		if (state==0) tempDisplay.setText("Waiting for inputs. Temperature: "+temp+" C");
		else if (state==1) tempDisplay.setText("Ramping to soak. Temperature: "+temp+" C");
		else if (state==2) tempDisplay.setText("Soaking. Temperature: "+temp+" C");
		else if (state==3) tempDisplay.setText("Ramping to reflow. Temperature: "+temp+" C");
		else if (state==4) tempDisplay.setText("Reflowing. Temperature: "+temp+" C");
		else if (state==5) tempDisplay.setText("Cooling Down. Temperature: "+temp+" C");
		else tempDisplay.setText("Temperature: "+temp+" C");
	}
	
	private Server initServer(){
		Server server = new Server(8085);
		server.setStopAtShutdown(true);
		WebAppContext wac = new WebAppContext();
		wac.setResourceBase("web");
		wac.setContextPath("/");
		wac.setDescriptor("web/web.xml");
		//HandlerList handlers = new HandlerList();
		server.setHandler(wac);
		return server;
	}
	
	private void startCom(){
		SerialComm[] ComPorts = SerialComm.getCommPorts();
		comStage = new Stage();
		HBox comInit = new HBox();
		Button setComPort = new Button();
		Label selectCom = new Label();
		final ComboBox ComList = new ComboBox();
		for (int i=0; i<ComPorts.length; i++){
            ComList.getItems().add(ComPorts[i].getSystemPortName());
		}
		
		Scene comScene = new Scene(comInit, 550, 75);
		comScene.getStylesheets().add("styleCom.css");
		
		selectCom.setText("Select COM Port:");
		setComPort.setText("Next");
		setComPort.setOnAction(new EventHandler<ActionEvent>(){
			@Override
			public void handle(ActionEvent event){
				com = SerialCom.initCom(ComList.getSelectionModel().selectedIndexProperty().get());
				comIn = com.getInputStream();
				comOut = com.getOutputStream();
				comStage.close();
			}
		});
		comInit.getChildren().addAll(selectCom,ComList, setComPort);
		comInit.setAlignment(Pos.CENTER);
		comInit.setId("comSet");
		comInit.setSpacing(15);
		comStage.setResizable(false);
		comStage.setOnCloseRequest(new EventHandler<WindowEvent>() {

            @Override
            public void handle(WindowEvent t) {
            	System.exit(0);
            }

        });
		comStage.setScene(comScene);
		comStage.showAndWait();
		
		
	}
	
	private void exportData(LinkedList<Integer> data) throws FileNotFoundException, UnsupportedEncodingException{
		PrintWriter writer = new PrintWriter("reflow-data.csv", "UTF-8");
		writer.println("Time, Temperature");
		for (int i=0; i<data.size(); i++){
			writer.println(i+","+data.get(i));
		}
		writer.close();
	}

}
