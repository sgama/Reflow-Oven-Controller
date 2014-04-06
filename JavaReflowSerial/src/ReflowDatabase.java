import java.sql.*;
import java.util.Date;

public class ReflowDatabase {

	final static String dbURL = "web/reflowdb.db";

  public static void main (String[] args){
	  //writeDB(1,150,100,200,30);
	 // updateDB(1,150,100,220,30);
	  //System.out.println(readDB(1)[2]);
	  //updateCurrentData(1,0,0);
	  System.out.println(readCurrentData()[0]);
	  System.out.println(readCurrentData()[1]);
	  System.out.println(readCurrentData()[2]);
  }
  
  public static void initDB ( )
  {
	    Connection c = null;
	    Statement stmt = null;
	    try {
	      Class.forName("org.sqlite.JDBC");
	      c = DriverManager.getConnection("jdbc:sqlite:"+dbURL);
	      stmt = c.createStatement();
	      String sql = "CREATE TABLE PROFILEDATA " +
	                   "(ID INT PRIMARY KEY          NOT NULL," +
	                   " SOAK_TEMP           INT     NOT NULL, " + 
	                   " SOAK_TIME           INT     NOT NULL, " + 
	                   " REFLOW_TEMP         INT     NOT NULL, " + 
	                   " REFLOW_TIME         INT     NOT NULL)"; 
	      String sql2 = "CREATE TABLE CURRENTDATA " +
	    		  "(ID INT PRIMARY KEY          NOT NULL," +
                  " CURRENT_TEMP           INT     NOT NULL, " + 
                  " CURRENT_STATE           INT     NOT NULL, " + 
                  " CURRENT_TIME         INT     NOT NULL)"; 
	      stmt.executeUpdate(sql);
	      stmt.close();
	      c.close();
	      c = DriverManager.getConnection("jdbc:sqlite:"+dbURL);
	      stmt = c.createStatement();
	      stmt.executeUpdate(sql2);
	      stmt.close();
	      c.close();
	    } catch ( Exception e ) {
	      System.err.println( e.getClass().getName() + ": " + e.getMessage() );
	      System.exit(0);
	    }
	    System.out.println("Opened/Created database successfully");
	  }
 
 public static void writeDB(int id, int stemp, int stime, int rtemp, int rtime) {
	 Connection c = null;
	    Statement stmt = null;
	    try {
	      Class.forName("org.sqlite.JDBC");
	      c = DriverManager.getConnection("jdbc:sqlite:"+dbURL);
	      c.setAutoCommit(false);
	      System.out.println("Opened database successfully");

	      stmt = c.createStatement();
	      String sql = "INSERT INTO PROFILEDATA (ID,SOAK_TEMP,SOAK_TIME,REFLOW_TEMP,REFLOW_TIME) " +
	                   "VALUES ("+ id +", " + stemp + ", " + stime +", " + rtemp + ", " + rtime +" );"; 
	      stmt.executeUpdate(sql);

	      stmt.close();
	      c.commit();
	      c.close();
	    } catch ( Exception e ) {
	      System.err.println( e.getClass().getName() + ": " + e.getMessage() );
	      System.exit(0);
	    }
	    System.out.println("Records created successfully");
 }
  
 public static int[] readDB(int ID) {
	 Connection c = null;
	 Statement stmt = null;
	 int  soak_temp = 0;
     int soak_time = 0;
     int  reflow_temp = 0;
     int reflow_time = 0;
	    try {
	      Class.forName("org.sqlite.JDBC");
	      c = DriverManager.getConnection("jdbc:sqlite:"+dbURL);
	      c.setAutoCommit(false);
	      //System.out.println("Opened database successfully");

	      stmt = c.createStatement();
	      ResultSet rs = stmt.executeQuery( "SELECT * FROM PROFILEDATA WHERE ID="+ID+";");
	      while ( rs.next() ) {
	         soak_temp = rs.getInt("soak_temp");
	         soak_time  = rs.getInt("soak_time");
	         reflow_temp = rs.getInt("reflow_temp");
	         reflow_time = rs.getInt("reflow_time");

	         //System.out.println( "Soak Temp: " + soak_temp );
	         //System.out.println( "Soak Time: " + soak_time );
	         //System.out.println( "Reflow Temp: " + reflow_temp );
	         //System.out.println( "Reflow Time: " + reflow_time );
	         //System.out.println();
	      }
	      rs.close();
	      stmt.close();
	      c.close();
	    } catch ( Exception e ) {
	      System.err.println( e.getClass().getName() + ": " + e.getMessage() );
	      System.exit(0);
	    }
	    //System.out.println("Operation done successfully");
	    return new int[]{soak_temp, soak_time, reflow_temp, reflow_time};
 }
 
 public static void updateDB (int id, int stemp, int stime, int rtemp, int rtime) {
	 Connection c = null;
	    Statement stmt = null;
	    try {
	      Class.forName("org.sqlite.JDBC");
	      c = DriverManager.getConnection("jdbc:sqlite:"+dbURL);
	      c.setAutoCommit(false);
	      System.out.println("Opened database successfully");

	      stmt = c.createStatement();
	      String sql = "UPDATE PROFILEDATA SET SOAK_TEMP=" + stemp + ",SOAK_TIME=" + stime +",REFLOW_TEMP=" + rtemp + ",REFLOW_TIME=" + rtime +" WHERE ID="+ id +";"; 
	      stmt.executeUpdate(sql);

	      stmt.close();
	      c.commit();
	      c.close();
	    } catch ( Exception e ) {
	      System.err.println( e.getClass().getName() + ": " + e.getMessage() );
	      System.exit(0);
	    }
	    System.out.println("Records created successfully");
}
  
 public static void updateCurrentData (int temp, int state, int time) {
	 Connection c = null;
	    Statement stmt = null;
	    try {
	      Class.forName("org.sqlite.JDBC");
	      c = DriverManager.getConnection("jdbc:sqlite:"+dbURL);
	      c.setAutoCommit(false);
	     // System.out.println("Opened database successfully");

	      stmt = c.createStatement();
	      String sql = "UPDATE CURRENTDATA SET CURRENT_TEMP=" + temp + ",CURRENT_STATE=" + state +",CURRENT_TIME=" + time + " WHERE ID=1;"; 
	      stmt.executeUpdate(sql);

	      stmt.close();
	      c.commit();
	      c.close();
	    } catch ( Exception e ) {
	      System.err.println( e.getClass().getName() + ": " + e.getMessage() );
	      System.exit(0);
	    }
	    //System.out.println("Records created successfully");
}
 
 public static void writeCurrentData(int temp, int state, int time) {
	 Connection c = null;
	    Statement stmt = null;
	    try {
	      Class.forName("org.sqlite.JDBC");
	      c = DriverManager.getConnection("jdbc:sqlite:"+dbURL);
	      c.setAutoCommit(false);
	      System.out.println("Opened database successfully");

	      stmt = c.createStatement();
	      String sql = "INSERT INTO CURRENTDATA (ID,CURRENT_TEMP,CURRENT_STATE,CURRENT_TIME) " +
	                   "VALUES (1, " + temp + ", " + state +", " + time + " );"; 
	      stmt.executeUpdate(sql);

	      stmt.close();
	      c.commit();
	      c.close();
	    } catch ( Exception e ) {
	      System.err.println( e.getClass().getName() + ": " + e.getMessage() );
	      System.exit(0);
	    }
	    System.out.println("Records created successfully");
 } 
 
 public static int[] readCurrentData() {
	 Connection c = null;
	 Statement stmt = null;
	 int  temp = 0;
     int time = 0;
     int  state = 0;
	    try {
	      Class.forName("org.sqlite.JDBC");
	      c = DriverManager.getConnection("jdbc:sqlite:"+dbURL);
	      c.setAutoCommit(false);
	      //System.out.println("Opened database successfully");

	      stmt = c.createStatement();
	      ResultSet rs = stmt.executeQuery( "SELECT * FROM CURRENTDATA WHERE ID=1;");
	      while ( rs.next() ) {
	         temp = rs.getInt("current_temp");
	         time  = rs.getInt("current_time");
	         state = rs.getInt("current_state");

	         //System.out.println( "Soak Temp: " + soak_temp );
	         //System.out.println( "Soak Time: " + soak_time );
	         //System.out.println( "Reflow Temp: " + reflow_temp );
	         //System.out.println( "Reflow Time: " + reflow_time );
	         //System.out.println();
	      }
	      rs.close();
	      stmt.close();
	      c.close();
	    } catch ( Exception e ) {
	      System.err.println( e.getClass().getName() + ": " + e.getMessage() );
	      System.exit(0);
	    }
	    //System.out.println("Operation done successfully");
	    return new int[]{temp, state, time};
 }



}