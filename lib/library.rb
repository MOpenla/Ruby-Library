require 'sqlite3'

=begin
= Library Class
=  Provides library related functions for a database
=  REQUIRES: SQLite Database table to be intitialized with:
=             CREATE TABLE books (
=                 isbn INTEGER PRIMARY KEY,
=                 title TEXT,
=                 author TEXT,
=                 status TEXT )
=             AND
=             CREATE TABLE rentedBooks (
=                 isbn INTEGER PRIMARY KEY,
=                 userID INTEGER,
=                 dateDue INTEGER )
=end
class Library
    #Initialize function
    # Opens the database connection with the provided file
    # REQUIRES: file STRING location of database file
    def initialize(file)
        @books = SQLite3::Database.new(file)       
    end
    
    #listCheckedOutBooks function
    # Lists the books checked out, who checked them out, and when they are due
    # OPTIONAL: id STRING can be passed in to display all the books checked
    #            out by a certain user.
    # RETURNS: The number of books checked out
    def listCheckedOutBooks(users, id = "%")
        num = 0
        
        @books.execute("
            SELECT * FROM rentedBooks INNER JOIN books ON
            rentedBooks.isbn = books.isbn
            WHERE userID LIKE ?",
        id) do |x|
            puts "Title:  #{x[4]}"
            puts "Author: #{x[5]}"
            puts "Due:    #{x[2]}"
            puts "Checked out By: #{users.getName(x[1])}"
            puts "--------------------------------------"
            
            num += 1
        end
        
        num
    end
    
    #seachBook function
    # Seaches for books that fit the given parameters and displays the
    #  title, author, isbn, and whether it is checked out or not.
    # Optional: params HASH
    #            KEYS: title, author, isbn, status
    #            VALUES: value to be seached for
    #           If Key is not provided, all results will be returned
    # If params is not provided, all books will be listed.
    # RETURNS: The number of books found
    def searchBook(params = {})
        num = 0
        
        # Convert empty fields to return all elements
        title = "%#{params["title"]}%"
        author = "%#{params["author"]}%"
        isbn = "%#{params["isbn"]}%"
        status = "%#{params["status"]}%"
    
    
        @books.execute("
            SELECT * FROM books WHERE
            title LIKE ? AND
            author LIKE ? AND
            isbn LIKE ? AND
            status LIKE ?",
        title, author, isbn, status) do |row|
            printBook(row)
            puts "-------------------------------"
            
            num += 1
        end
        
        num
    end
    
    #addBook function
    # Adds a book to the database with the given parameters.
    # REQUIRES: params
    #            KEYS: isbn, title, author
    #            VALUES: value to be added
    # OPTIONAL: params["status"]
    #            If no status is given, it will default to available
    # RETURNS: HASH["success"] = true if book successfully added,
    #                            false otherwise
    #              ["error"]   = "ERROR MESSAGE" if there was an error
    def addBook(params)
        r = {"success" => false}
        
        r["error"] = "Missing isbn key"   if not params.has_key?("isbn")
        r["error"] = "Missing title key"  if not params.has_key?("title")
        r["error"] = "Missing author key" if not params.has_key?("author")
        
        if not r.has_key?("error") and not hasISBN?(params["isbn"])
            params["status"] = "available" if params["status"] == nil
            
            @books.execute("
                INSERT INTO books 
                VALUES (?, ?, ?, ?)",
                params["isbn"],
                params["title"],
                params["author"],
                params["status"]
            )
            
            r["success"] = true
        else
            r["error"] = "ISBN already exists"
        end
        r
    end
    
    #removeBook function
    # Removes a book from the database
    # REQUIRES: isbn INTEGER. ISBN of the book to be deleted
    # RETURNS: HASH["success"] = true if book successfully deleted,
    #                            false otherwise
    #              ["error"]   = "ERROR MESSAGE" if there was an error
    def removeBook(isbn)
        r = {"success" => false}
        
        if hasISBN?(isbn)
            @books.execute("DELETE FROM books WHERE isbn = ? LIMIT 1", isbn)
            r["success"] = true
        else
            r["error"] = "Invalid ISBN"
        end
        
        r
    end
    
    #updateBook function
    # Updates the given book in the database with new parameters
    # REQUIRES: isbn INTEGER. ISBN of the book to be updated
    #           newParms HASH containing the parameters to be updated and their values
    # OPTIONAL: newParams
    #            KEYS: title, author, status
    #            VALUES: new value for the field
    #           If KEY is not provided, or its field is empty, the old value
    #            will be used.
    # RETURNS: HASH["success"] = true if the book was successfully updated,
    #                            false otherwise
    #              ["error"]   = "ERROR MESSAGE" if there was an error
    def updateBook(isbn, newParams)
        r = { "success" => false }
        
        if hasISBN?(isbn)
            # Populate old values if new values aren't provided
            #TODO make this code look cleaner
            @books.execute("SELECT * FROM books WHERE isbn = ? LIMIT 1", isbn) do |book|
                newParams["title"] = book[1] if 
                    (newParams["title"] == nil or newParams["title"] == "")
                newParams["author"] = book[2] if 
                    (newParams["author"] == nil or newParams["author"] == "")
                newParams["status"] = book[3] if 
                    (newParams["status"] == nil or newParams["status"] == "")
            end
            
            if removeBook(isbn)["success"]
                newParams["isbn"] = isbn
                r["success"] = addBook(newParams)["success"]
            end
            
            r["success"] = true
        else
            r["success"] = false
            r["error"] = "Not a valid ISBN"
        end
        
        r
    end
    
    #checkOutBook function
    # Changes a book's status to 'checked out' and adds it to the rentedBooks table
    #  Due date is set for two weeks from checkout date
    # REQUIRES: isbn INTEGER of the book to be checked out
    #           userID INTEGER of the user checking out the book
    def checkOutBook(isbn, userID)
        #TODO make the due date changeable
        dueDate = (Time.now + (2*7*24*60*60)).strftime("%Y%m%d").to_i
        
        #TODO error checking -- make sure vaild isbn and isn't already checked out
        @books.execute("
            INSERT INTO rentedBooks
            VALUES (?, ?, ?)",
            isbn,
            userID,
            dueDate
        )
        
        updateBook(isbn, {"status" => "checked out"})
        
        #TODO return due date if successful, error message otherwise
        puts "#{isbn} is due #{dueDate}"
    end
    
    #checkInBook function
    # Changes a checked out book's status to 'available' and removes it from
    #  the rentedBooks table
    # REQUIRES: isbn INTEGER of the book to be checked in
    # RETURNS: true if book was successfully checked in,
    #          false otherwise
    def checkInBook(isbn)
        #TODO error checking
        successful = false
        
        @books.execute("DELETE FROM rentedBooks WHERE isbn = ?", isbn)
        updateBook(isbn, {"status" => "available"})
        
        successful = true
        successful
    end
    
    #printBook function
    # PRIVATE FUNCTION
    # Prints the passed in book array in a readable format
    def printBook(book)
        puts "Title:  #{book[1]}"
        puts "Author: #{book[2]}"
        puts "ISBN:   #{book[0]}"
        puts "Status: #{book[3]}"
    end
    
    #hasISBN? function
    # PRIVATE FUNCTION
    # REQUIRES: isbn INTEGER to be searched for
    # RETURNS: true if books table contains the isbn,
    #          false otherwise
    def hasISBN?(isbn)
        has = false
        
        @books.execute("SELECT isbn FROM books WHERE isbn = ?", isbn){ has = true }
        
        has
    end
end #End of Library Class


=begin
= Requests Class
=  Handles book requests
=  REQUIRES: SQLite Database table to be intitialized with:
=             CREATE TABLE bookRequests (
=                 requestID INTEGER PRIMARY KEY ASC,
=                 userID INTEGER,
=                 title TEXT,
=                 author TEXT,
=                 dateRequested INTEGER)
=end
class Requests
    #Initialize function
    # Opens the database connection with the provided file
    # REQUIRES: file STRING location of database file
    def initialize(file)
        @req = SQLite3::Database.new(file)       
    end
    
    #requestBook function
    # Adds a book to the bookRequests table
    # REQUIRES: usrID INTEGER - userID of the person making the request
    #           params HASH -
    #            KEYS: title, author
    #            VALUES: values to be added to the request fields
    # RETURNS: true if the request was successfully added,
    #          false otherwise
    def requestBook(usrID, params)
        completed = false
        
        requestID = 1
        date = Time.now.strftime("%Y%m%d").to_i
        
        @req.execute("
            SELECT requestID FROM bookRequests ORDER BY requestID DESC LIMIT 1
        ") do |x|
            requestID += x[0]
        end
        
        @req.execute("
            INSERT INTO bookRequests
            VALUES (?, ?, ?, ?, ?)",
            requestID,
            usrID,
            params["title"],
            params["author"],
            date
        )
        
        completed = true
        completed
    end
    
    #getNumber function
    # Counts the number of requests
    # RETURNS: the number of requests in the bookRequests table
    def getNumber
        num = 0
        
        @req.execute("SELECT * FROM bookRequests") do |x|
            num += 1
        end
        
        num
    end
    
    #view function
    # Prints all the requests, who made the request, and when the request was placed
    def view
        #TODO replace profiles SQL search with a call
        @req.execute("SELECT * FROM bookRequests") do |request|
            @req.execute(
                "SELECT firstName, lastName FROM profiles WHERE userID = ? LIMIT 1", 
                request[1]) do |user|
                puts "#{request[0]}. #{request[2]} by #{request[3]}" 
                puts "    was requested by #{user[0]} #{user[1]} on #{request[4]}"
            end
        end
    end
    
    #delete function
    # Deletes a request from the database
    # REQUIRES: num INTEGER - the request ID of the request to be deleted
    # RETURNS: true if request was successfully deleted,
    #          false otherwise
    def delete(num)
        #TODO error checking
        successful = false
        @req.execute("DELETE FROM bookRequestes WHERE requestID = ?", num)
        successful = true
        successful
    end
end
