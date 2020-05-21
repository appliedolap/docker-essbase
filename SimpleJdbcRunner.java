import java.io.File;
import java.io.FileNotFoundException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

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

	public static final Integer DEFAULT_CONNECT_ATTEMPTS = 5;
	
	public static final Integer DEFAULT_CONNECT_DELAY = 5;
	
	public static final String OPT_CONNECT_ATTEMPTS = "connect-attempts";
	
	public static final String OPT_CONNECT_DELAY = "reconnect-delay";
	
	/**
	 * Example invocation:
	 * 
	 * <pre>
	 * args = new String[] {"-driver", "net.sourceforge.jtds.jdbc.Driver", "-url",
	 *	 "jdbc:jtds:sqlserver://docker1:1401;appName=RazorSQL;useCursors=true", "-username", "sa",
	 *	 "-connect-attempts", "12", 
	 *	 "-password", "ABcd12#$", "-query", "SELECT 1;SELECT 2;DROP DATABASE IF EXISTS HFM1;CREATE DATABASE HFM1",
	 *	 "-file", "ddl.sql"};
	 * </pre>
	 * 
	 * @param args
	 */
	public static void main(String[] args) {
		 
		Map<String, String> options = new HashMap<String, String>();
		options.put(OPT_CONNECT_ATTEMPTS, DEFAULT_CONNECT_ATTEMPTS.toString());
		options.put("reconnect-delay", DEFAULT_CONNECT_DELAY.toString());
		options.putAll(parseOptions(args));
		
		try {
			new SimpleJdbcRunner(options);
		} catch (FileNotFoundException e) {
			System.err.println("Could not find file: " + e.getMessage());
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

	public SimpleJdbcRunner(Map<String, String> options) throws SQLException, ClassNotFoundException, InterruptedException, FileNotFoundException {
		if (options.containsKey("driver")) {
			Class.forName(options.get("driver"));
		}

		int connectAttempts = Integer.parseInt(options.get(OPT_CONNECT_ATTEMPTS));
		int reconnectDelay = Integer.parseInt(options.get(OPT_CONNECT_DELAY));
		
		Connection connection = null;
		for (int attempt = 1; attempt < connectAttempts; attempt++) {
			try {
				connection = DriverManager.getConnection(options.get("url"), options.get("username"), options.get("password"));
				break;
			} catch (SQLException e) {
				System.err.println("Unable to connect to database on attempt " + attempt + ", waiting " + reconnectDelay + "s before attempting again, will try " + (connectAttempts - attempt) + " more times");
				System.err.println("Error was: " + e.getMessage());
				Thread.sleep(reconnectDelay * 1000);
			}
		}
		
		if (options.get("query") != null) {
			String queries[] = options.get("query").split(";");
			for (String query : queries) {
				Statement statement = connection.createStatement();
				System.out.println("Executing: " + query);
				// returns true if the return object is a result set, false otherwise
				statement.execute(query);
				statement.close();
			}
		}
		
		String filename = options.get("file");
		String delimiter = options.get("delimiter");
		
		if (delimiter == null) delimiter = ";";
		
		if (filename != null) {
			File sqlFile = new File(filename);
			if (!sqlFile.exists()) {
				throw new FileNotFoundException(filename);
			}
			Scanner scanner = new Scanner(sqlFile);
			
			if (!options.containsKey("line-by-line")) {
				scanner.useDelimiter(delimiter);
				while (scanner.hasNext()) {
					String sqlLine = scanner.next().trim();
					if (!sqlLine.isEmpty()) {
						System.out.println("SQL Line: " + sqlLine);
						Statement statement = connection.createStatement();
						statement.execute(sqlLine);
						statement.close();
					}
				}
			} else {
				while (scanner.hasNextLine()) {
					String sqlLine = scanner.nextLine().trim();
					if (!sqlLine.isEmpty()) {
						System.out.println("SQL Line: " + sqlLine);
						Statement statement = connection.createStatement();
						statement.execute(sqlLine);
						statement.close();
					}
				}
			}
			scanner.close();
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
			// always advance index even if it wasn't a valid option
			currentIndex += 1;
		}
		return options;
	}
	
}

