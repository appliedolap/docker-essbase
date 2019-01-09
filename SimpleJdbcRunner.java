import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;

/**
 * A very simple Java class that can run SQL statements against a given database using a supplied
 * driver and credentials. This program is very intentionally designed as a single class without a
 * package in order to facilitate copying, compiling, and running on a target system.
 * 
 * <p>
 * The requirements of the target system are that that a JDK is available. Specifically, you'll need
 * to compile with <code>javac</code> and then run with <code>java</code>.
 * 
 * @author jasonwjones
 *
 */
public class SimpleJdbcRunner {

	/**
	 * The prefix to look for on options
	 */
	private static final String OPTION_PREFIX = "-";

	/**
	 * If an option is specified but does not have a value, then it will automatically be assigned a
	 * value of <code>true</code>
	 */
	private static final String TRUE = "true";

	/**
	 * E
	 * 
	 * @param args
	 */
	public static void main(String... args) {

		 //args = new String[] {"-driver", "net.sourceforge.jtds.jdbc.Driver", "-url",
		 //"jdbc:jtds:sqlserver://docker1;appName=RazorSQL;useCursors=true", "-username", "sa",
		 //"-connect-attempts", "12", 
		 //"-password", "ABcd12#$", "-query", "SELECT 1;SELECT 2;DROP DATABASE IF EXISTS HFM1;CREATE DATABASE HFM1"};
		 
		Map<String, String> options= new HashMap<String, String>();
		options.put("connect-attempts", "5");
		options.put("reconnect-delay", "5");
		options.putAll(parseOptions(args));
		
		try {
			new SimpleJdbcRunner(options);
		} catch (SQLException e) {
			System.err.println("SQL error: " + e.getMessage());
			e.printStackTrace(System.err);
		} catch (ClassNotFoundException e) {
			System.err.println("Couldn't load driver class: " + e.getMessage());
		} catch (InterruptedException e) {
			System.err.println("Execution was canceled");
			Thread.currentThread().interrupt();
		}

	}

	public SimpleJdbcRunner(Map<String, String> options) throws SQLException, ClassNotFoundException, InterruptedException {
		if (options.containsKey("driver")) {
			Class.forName(options.get("driver"));
		}

		int connectAttempts = Integer.parseInt(options.get("connect-attempts"));
		int reconnectDelay = Integer.parseInt(options.get("reconnect-delay"));
		
		Connection connection = null;
		for (int attempt = 1; attempt < connectAttempts; attempt++) {
			try {
				connection = DriverManager.getConnection(options.get("url"), options.get("username"), options.get("password"));
				break;
			} catch (SQLException e) {
				System.err.println("Unable to connect to database on attempt " + attempt + ", waiting " + reconnectDelay + "s before attempting again, will try " + (connectAttempts - attempt) + " more times");
				Thread.sleep(reconnectDelay * 1000);
			}
		}
		
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

	/**
	 * Iterates through an array of strings and generates a map of options and their values. An
	 * option must start with the {@link #OPTION_PREFIX}, which by default is
	 * {@value #OPTION_PREFIX}. If the prefix is detected then the next value is checked to see if
	 * it contains a value. If it's not value, doesn't exist, or is another option name, then the
	 * option is assumed to be a boolean value and will be assigned the string value of
	 * {@link #TRUE}.
	 * 
	 * For example, given the following input:
	 * 
	 * <pre>bad_option -foo bar -baz</pre>
	 * 
	 * <p>Then the map would be expected to contain <code>foo -> bar</code> and
	 * <code>baz -> true</code>. Note that the first option is discarded in this case since it's in
	 * an invalid location.
	 * 
	 * @param optionArguments an array of options to parse
	 * @return a map with the options and their values, be they implicit or explict
	 */
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

