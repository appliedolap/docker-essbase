import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;

public class SimpleJdbcRunner {

	private static final String OPTION_PREFIX = "-";
	
	private static final String TRUE = "true";
	
	//private Map<String, String> options;
	
	public static void main(String... args) {
		
		//String[] args2 = new String[] {"-driver", "net.sourceforge.jtds.jdbc.Driver", "-url", "jdbc:jtds:sqlserver://docker1;appName=RazorSQL;useCursors=true", "-username", "sa", "-password", "ABcd12#$", "-query", "SELECT 1;SELECT 2;DROP DATABASE IF EXISTS HFM1;CREATE DATABASE HFM1"};
		
		Map<String, String> options = parseOptions(args);
		
		System.out.println("Context:");
		for (Map.Entry<String, String> entry : options.entrySet()) {
			System.out.println("\t" + entry.getKey() + " = " + entry.getValue());
		}
		
		try {
			new SimpleJdbcRunner(options);
		} catch (SQLException e) {
			System.err.println("SQL error: " + e.getMessage());
			e.printStackTrace(System.err);
		} catch (ClassNotFoundException e) {
			System.err.println("Couldn't load driver class: " + e.getMessage());
		}		

	}
	
	public SimpleJdbcRunner(Map<String, String> options) throws SQLException, ClassNotFoundException {
		//this.options = options;
		
		if (options.containsKey("driver")) {
			Class.forName(options.get("driver"));	
		}
		
		Connection connection = DriverManager.getConnection(options.get("url"), options.get("username"), options.get("password"));
		
		String queries[] = options.get("query").split(";");
		for (String query : queries) {
			Statement statement = connection.createStatement();
			System.out.println("Executing: " + query);
			// returns true if the return object is a result set, false otherwise
			statement.execute(query);
			statement.close();
		}
		connection.close();
	}
	
	public static Map<String, String> parseOptions(String... optionArguments) {
		Map<String, String> options = new HashMap<String, String>();
		
		for (int currentIndex = 0; currentIndex < optionArguments.length;) {
			String currentItem = optionArguments[currentIndex];
			if (currentItem.startsWith(OPTION_PREFIX)) {
				if (currentIndex + 1 < optionArguments.length) {
					String nextItem = optionArguments[currentIndex + 1];
					if (nextItem.startsWith(OPTION_PREFIX)) {
						// it's a normal option, so just consider the current option to be boolean
						options.put(currentItem.substring(1), TRUE);
					} else {
						// otherwise the next thing is the option value
						options.put(currentItem.substring(1), nextItem);
						currentIndex += 1;
					}
				} else {
					options.put(currentItem.substring(1), TRUE);
				}
			}
			// always advanced index even if it wasn't a valid option
			currentIndex += 1;
		}
		return options;
	}
	
}

