<?php
require_once('../lib/datagrid-master/lazy_mofo.php');

$db_host = 'localhost';
$db_name = 'BOOKSTORE'; 
$db_user = 'root';
$db_pass = ''; 

try {
    $dbh = new PDO("mysql:host=$db_host;dbname=$db_name;", $db_user, $db_pass);
    $dbh->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die('PDO connection error: ' . $e->getMessage());
}

session_start();

// logout 
if (isset($_GET['action']) && $_GET['action'] == 'logout') {
    session_destroy();
    header("Location: " . $_SERVER['PHP_SELF']); //redirect user to same page
    exit;
}

// account info view
if (isset($_GET['action']) && $_GET['action'] == 'account_info') {
    
    // 'back' button
    echo "<div style='padding: 20px;'>";
    echo "<a href='" . $_SERVER['PHP_SELF'] . "'>&laquo; Back</a>";
    echo "<h1>My Account</h1>";

    // account details grid
    $lm_profile = new lazy_mofo($dbh, 'en-us');
    $lm_profile->table = 'CUSTOMERS';
    $lm_profile->identity_name = 'Cust_id';
    $lm_profile->grid_sql = "SELECT * FROM CUSTOMERS WHERE Cust_id = :cust_id";
    $lm_profile->grid_sql_param[':cust_id'] = $_SESSION['logged_in_cust'];  
    $lm_profile->grid_show_search_box = false;
    $lm_profile->grid_add_link = ""; 
    $lm_profile->grid_export_link = "";
    $lm_profile->run();

    // account orders grid
    echo "<hr><h3>My Orders</h3>";
    $lm_orders = new lazy_mofo($dbh, 'en-us');
    $lm_orders->table = 'ORDERS'; 
    $lm_orders->identity_name = 'Order_id';
    $lm_orders->grid_sql = "
        SELECT o.Order_id, o.Status, b.Title, o.Order_id 
        FROM ORDERS o
        JOIN BOOK_ORDERS bo ON o.Order_id = bo.Order_id
        JOIN BOOKS b ON bo.Isbn = b.Isbn
        WHERE o.Cust_id = :cust_id
        ORDER BY o.Order_id DESC
    ";  
    $lm_orders->grid_sql_param[':cust_id'] = $_SESSION['logged_in_cust'];
    $lm_orders->grid_show_search_box = false;
    $lm_orders->grid_add_link = "";   
    $lm_orders->grid_edit_link = ""; 
    $lm_orders->grid_delete_link = "";
    $lm_orders->grid_export_link = "";
    $lm_orders->run();
    
    // account reviews grid
    echo "<hr><h3>My Reviews</h3>";
    $lm_reviews = new lazy_mofo($dbh, 'en-us');
    $lm_reviews->table = 'REVIEWS';  
    $lm_reviews->identity_name = 'Cust_id';
    $lm_reviews->grid_sql = "
        SELECT r.Cust_id, r.Isbn, r.Rating, r.Comm, b.Title, a.Name
        FROM REVIEWS r
        JOIN BOOKS b ON r.Isbn = b.Isbn 
        JOIN WRITTEN_BY w on b.Isbn = w.Isbn 
        JOIN AUTHORS a on w.Author_id = a.Author_id
        WHERE r.Cust_id = :cust_id
        ORDER BY b.Title DESC
    ";  
    $lm_reviews->grid_sql_param[':cust_id'] = $_SESSION['logged_in_cust'];
    $lm_reviews->grid_show_search_box = false;
    $lm_reviews->grid_add_link = "";  
    $lm_reviews->run();
    echo "</div>";  
    exit; // stop script so that customer remains on info page 
}  // end of account info view

// user login
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['login_btn'])) {	 
    $user_name = $_POST['user_name'];
    $password = $_POST['password'];

    // query the CUSTOMERS table
    $stmt = $dbh->prepare("SELECT * FROM CUSTOMERS WHERE User_name = :user AND Password = :pass"); // returns PDOStatement object from database connection
    $stmt->execute([':user' => $user_name, ':pass' => $password]); // execute PDOstatement replace ':___' with actual credentials from SQL query
    $cust = $stmt->fetch(PDO::FETCH_ASSOC); // fetch next row from result set return by executed sql query

    // if success -> save ID to session
    if ($cust) { 	
        $_SESSION['logged_in_cust'] = $cust['Cust_id'];  
        $_SESSION['cust_f_name'] = $cust['First_name'];
        header("Location: " . $_SERVER['PHP_SELF']); //redirect user back to this same page (but logged in)
        exit;
    } else {
        $login_error = "Invalid Username or Password"; // if fails store error to print later
    }
}

// admin login
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['admin_login_btn'])) {
    $admin_id = $_POST['admin_id'];
    $admin_password = $_POST['admin_password'];
    $stmt = $dbh->prepare("SELECT * FROM ADMINS WHERE Admin_id = :admin_id AND Password = :admin_password");
    $stmt->execute([':admin_id' => $admin_id, ':admin_password' => $admin_password]);
    $admin = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($admin) {
        $_SESSION['logged_in_admin'] = true; 
        header("Location: " . $_SERVER['PHP_SELF']);
        exit;
    } else {
        $login_error = "Invalid Admin Credentials";
    }
}
if (isset($_GET['view']) && $_GET['view'] == 'admin_login') {
        echo "<html><body style='font-family: sans-serif; padding: 50px;'>";
        echo "<h2>Admin Login</h2>";
        
        if (isset($login_error)) { echo "<p style='color:red'>$login_error</p>"; }

        echo "<form method='post' action=''>"; 
        echo "<label>Admin User:</label><br><input type='text' name='admin_id' required><br><br>";
        echo "<label>Password:</label><br><input type='password' name='admin_password' required><br><br>";
        echo "<input type='submit' name='admin_login_btn' value='Login'>";
        echo "</form>";
        echo "<br><hr><br>";
        echo "<a href='" . $_SERVER['PHP_SELF'] . "'>&laquo; Back to Customer Login</a>";
        echo "</body></html>";
        exit; 
}
 
// customer view
if (isset($_SESSION['logged_in_cust'])) { 
	// book purchase logic
	if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['purchase_book'])) {
	    	$purchase_isbn= $_POST['Isbn'];
	    	$cust_id = $_SESSION['logged_in_cust'];
	    	$status = 'incomplete';
	    	$payment_method = $_POST['Payment_method'];
	    	$time_stamp = date('Y-m-d H:i:s');
	    	$stmt_order = $dbh->prepare("INSERT INTO ORDERS (Cust_id, Status) VALUES (:cust_id, :status)");
	    	$stmt_order->bindParam(':cust_id', $cust_id);
	    	$stmt_order->bindParam(':status', $status);
	    	$stmt_order->execute();
	    	$n_order_id = $dbh->lastInsertId(); //PDO method for retreiving last entry
	    
	    	$stmt_book_order=$dbh->prepare("INSERT INTO BOOK_ORDERS (Order_id, Isbn) VALUES (:order_id, :isbn)");
	    	$stmt_book_order->bindParam('order_id', $n_order_id);
	    	$stmt_book_order->bindParam('isbn', $purchase_isbn);
	    	$stmt_book_order->execute();
	    
	    	$stmt_book_payment=$dbh->prepare("INSERT INTO ORDERS_PAYMENT (Order_id, Payment_method, Time_stamp) VALUES (:order_id, :payment_method, :time_stamp)");
            	$stmt_book_payment->bindParam('order_id', $n_order_id);
	    	$stmt_book_payment->bindParam('payment_method', $payment_method);
	    	$stmt_book_payment->bindParam('time_stamp', $time_stamp);	    
		$stmt_book_payment->execute();
	    	header("Location: " . $_SERVER['PHP_SELF']);
	    	exit;
	}
	
	// welcome bar
	echo "<div style='background:#eee; padding:10px; text-align:right;'>";
	echo "Welcome, " . htmlspecialchars($_SESSION['cust_f_name']) . " | ";
	echo "<a href='?action=account_info'>Account Info</a>";
	echo " <span style='margin: 0 3px;'>|</span> ";
	echo "<a href='?action=logout'>Logout</a>";
	echo "</div>";

	// books grid
	$lm = new lazy_mofo($dbh, 'en-us');
	echo "<h2>1. Available Books</h2>";
	$lm_books = new lazy_mofo($dbh, 'en-us');
	$lm_books->table = 'BOOKS';
	$lm_books->identity_name = 'book_id';
	$lm_books->grid_show_search_box = true;
	$lm_books->grid_export_link = "";
	$lm_books->grid_add_link = "";
	$lm_books->grid_sql = "
	SELECT Isbn, Title, Edition, Price, book_id 
	FROM BOOKS 
	WHERE coalesce(Title, '') LIKE :_search_b 
	   OR coalesce(Isbn, '')  LIKE :_search_b 
	ORDER BY book_id DESC
	";
	$lm_books->grid_sql_param[':_search_b'] = '%' . trim($_REQUEST['_search'] ?? '') . '%';
	$lm_books->form_sql = "SELECT * FROM BOOKS WHERE book_id = :id";
	$lm_books->form_sql_param[':id'] = intval($_REQUEST['book_id'] ?? 0);
	$lm_books->form_input_control['book_id'] = array('type' => 'hidden');
	$lm_books->grid_edit_link = "";
	$lm_books->grid_delete_link = "";
	$lm_books->grid_export_link = "";
	$lm_books->run(); 
	
	//book purchase UI
	echo "<html><body>";
	echo "<h2>Purchase a Book</h2>";
	echo "<form method='post' action=''>";
	echo "<label for='Isbn'>Isbn:</label>";
	echo "<input type='text' id='Isbn' name='Isbn' required><br><br>";
	echo "<label for='payment_method'>Payment Method:</label>";
	echo "<input type='text' id='payment_method' name='Payment_method' required><br><br>";
	echo "<input type='submit' name='purchase_book' value='Purchase Book'>";
	echo "</form>";
	echo "</body></html>";
}

// admin view
elseif (isset($_SESSION['logged_in_admin'])) { 
	
	// welcome bar
	echo "<div style='background:#eee; padding:10px; text-align:right;'>";
	echo "Welcome, " . htmlspecialchars($_SESSION['logged_in_admin']) . " | ";
	echo "<a href='?action=logout'>Logout</a>";
	echo "</div>";

	// customers grid
	$lm_customers = new lazy_mofo($dbh, 'en-us');
	$lm_customers->table = 'CUSTOMERS';
	$lm_customers->identity_name = 'Cust_id';
	$lm_customers->grid_show_search_box = true;
	$lm_customers->grid_sql = "
	SELECT
	  First_name
	  , Last_name
	  , Cust_id
	FROM CUSTOMERS
	WHERE coalesce(Cust_id, '') LIKE :_search
	   OR coalesce(First_name, '')  LIKE :_search
	   OR coalesce(Last_name, '')   LIKE :_search -- Added Last_name to search filter
	ORDER BY Cust_id DESC
	";
	$lm_customers->grid_sql_param[':_search'] = '%' . trim($_REQUEST['_search'] ?? '') . '%';
	$lm_customers->form_sql = "
	SELECT
	First_name
	  , Last_name
	  , Cust_id 
	FROM CUSTOMERS
	WHERE Cust_id = :Cust_id
	";
	$lm_customers->form_sql_param[':Cust_id'] = intval($_REQUEST['Cust_id'] ?? 0);
	$lm_customers->form_input_control['Cust_id'] = array('type' => 'hidden');
	echo "<html><body>";
	echo "<h2>Manage Customers</h2>"; 
	$lm_customers->run();   
	

	// orders grid
	echo "<hr style='margin: 40px 0;'>";
	echo "<h2> Order Entry</h2>";
	echo "<form id='inline_add_form' method='post'></form>";
	echo "<div id='order_grid_container'>";
	$lm_orders = new lazy_mofo($dbh, 'en-us');
	$lm_orders->table = 'BOOK_ORDERS'; 
	$lm_orders->identity_name = 'Order_id';
	$lm_orders->grid_show_search_box = true;
	$lm_orders->grid_sql = "
	SELECT 
	  bo.Isbn,
	  b.Title,
	  o.Order_date,
	  o.Status,
	  bo.Order_id 
	FROM BOOK_ORDERS bo
	LEFT JOIN ORDERS o ON bo.Order_id = o.Order_id
	LEFT JOIN BOOKS b  ON bo.Isbn = b.Isbn
	WHERE coalesce(b.Title, '') LIKE ? 
	   OR coalesce(o.Status, '') LIKE ?
	ORDER BY bo.Order_id DESC
	";
	$search_term = '%' . trim($_REQUEST['_search'] ?? '') . '%';
	$lm_orders->grid_sql_param = array($search_term, $search_term);
	$lm_orders->form_sql = "SELECT Order_id, Isbn FROM BOOK_ORDERS WHERE Order_id = :id";
	$lm_orders->form_sql_param = array(':id' => intval($_REQUEST['Order_id'] ?? 0));
	$lm_orders->form_input_control['Order_id'] = array('type' => 'hidden');
	$lm_orders->run();
	echo "</div>";
	echo "</body></html>";
}

// if 'logged_in_admin' DNE -> NOT logged in, show Login Form (prevent access)
else{ 		
    	echo "<html><body style='font-family: sans-serif; padding: 50px;'>";
    	echo "<h2>Customer Login</h2>";
    	if (isset($login_error)) { echo "<p style='color:red'>$login_error</p>"; } 
    
    // login form
    echo "<form method='post'>";
    echo "<label>Username:</label><br>";
    echo "<input type='text' name='user_name' required><br><br>";
    echo "<label>Password:</label><br>";
    echo "<input type='password' name='password' required><br><br>";
    echo "<input type='submit' name='login_btn' value='Login'>";
    echo "</form>";
    echo "</body></html>";
    
    // new user registration, some cleverness here by using lm
    $lm_register = new lazy_mofo($dbh, 'en-us');
    $lm_register->table = 'CUSTOMERS';
    $lm_register->identity_name = 'Cust_id';
    echo "<h2>Register New User</h2>";
    $lm_register->grid_sql = "SELECT * FROM CUSTOMERS WHERE 1=0";
    $lm_register->grid_add_link = "<a href='" . $_SERVER['PHP_SELF'] . "?action=edit&_table=" . $lm_register->table . "' class='lm_grid_add_link'>Register</a>";
    $lm_register->grid_export_link = "";
    $lm_register->grid_text_no_records_found = "";
    $lm_register->form_sql = "
	    SELECT 
		Cust_id, 
		First_name, 
		Last_name, 
		User_name, 
		Address, 
		Phone_num, 
		Password
	    FROM CUSTOMERS
	    WHERE Cust_id = :id
	";
    $lm_register->form_sql_param[':id'] = intval($_REQUEST['Cust_id'] ?? 0); 
    $lm_register->run(); 

    // admin login button	
    echo '<div style="margin-top: 70px;"> <h3 style="margin-bottom: 15px;">Are you an Admin?</h3> </div>';
    echo "<form method='get' action=''>";
    echo "<input type='hidden' name='view' value='admin_login'>";
    echo "<input type='submit' value='Admin Login'>";
    echo "</form>";
    exit; // user remains on the login page
}
?>
