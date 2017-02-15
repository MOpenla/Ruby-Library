require './lib/users'
require './lib/library'

$database = "database/database.db"

def welcome
    puts  "***************************************"
    puts  "* 1. Login                            *"
    puts  "* 2. Exit Program                     *"
    print "* Please select an option (1 or 2): "
    selection = gets.to_i == 1
    puts  "***************************************"
    puts
    
    #TODO error checking
    
    selection
end

def login(users)
    print "Please enter login: "
    username = gets.chomp #Chomp to remove end line character
    
    attempt = 1
    while not users.validLogin?(username)
        if attempt >= 5
            puts "Too many attempts"
            exit
        end
        
        puts "Invalid login"
        print "Please enter a valid login: "
        username = gets.chomp
        attempt += 1
    end
    
    #TODO add password checking
    #TODO add way for the user to for stop
    
    Profile.new($database, users.getID(username))
end

def getAdminOption
    puts  "***************************************"
    puts  "* 1. List Books                       *"
    puts  "* 2. List Available Books             *"
    puts  "* 3. List Checked Out Books           *"
    puts  "* 4. Search for Book                  *"
    puts  "* 5. Add Books                        *"
    puts  "* 6. Modify a Book                    *"
    puts  "* 7. Delete a Book                    *"
    puts  "* 8. Manage Requests                  *"
    puts  "* 9. Add User                         *"
    puts  "*                                     *"
    puts  "* 0. Logout                           *"
    print "* Please select an option (1 - 8): "
    selection = gets.to_i
    puts  "***************************************"
    puts
    
    #TODO error checking
    
    selection
end

def getUserOption
    puts  "***************************************"
    puts  "* 1. List Books                       *"
    puts  "* 2. List Available Books             *"
    puts  "* 3. Search for Book                  *"
    puts  "* 4. View Your Books                  *"
    puts  "* 5. Request Book                     *"
    puts  "* 6. Checkout Book                    *"
    puts  "* 7. Retrun Book                      *"
    puts  "*                                     *"
    puts  "* 0. Logout                           *"
    print "* Please select an option (1 - 7): "
    selection = gets.to_i
    puts  "***************************************"
    puts
    
    #TODO error checking
    
    selection
end

def bookSearch(lib)
    puts "-------------Book Search-------------"
    puts "NOTE: Leaving a field blank will return all results for that field"
    puts
    
    continue = true
    
    while continue
        input = {}
            
        print "Title: "
        input["title"] = gets.chomp
        print "Author: "
        input["author"] = gets.chomp
        print "ISBN: "
        input["isbn"] = gets.chomp
        print "Status (1 for available, 2 for checked out): "
        s = gets.to_i
        input["status"] = "available"   if s == 1
        input["status"] = "checked out" if s == 2
        puts
        
        lib.searchBook(input)
        
        puts
        print "Search for another book (y for yes)? "
        continue = gets.chomp == "y"
        puts
    end
end

users = Users.new($database)
library = Library.new($database)

puts "Hello and weclome to the Library Managment System"
puts

continue = welcome

while continue
    user = login(users)
    puts
    puts "Welcome #{user.fName} #{user.lName}"
    
    if user.isAdmin #Admin
        requests = Requests.new($database)
        puts "There are currently #{requests.getNumber} requests"
        option = getAdminOption
        
        while not option == 0
            if option == 1 #List Books
                num = library.searchBook
                
                puts "There are no books in the library" if num == 0
                puts
            elsif option == 2 #List Available Books
                num = library.searchBook( {"status" => "available"} )
                
                puts "There are currently no books available" if num == 0
                puts
            elsif option == 3 #List Checked Out Books
                num = library.listCheckedOutBooks(users)
                
                puts "There are currently no books checked out" if num == 0
                puts
            elsif option == 4 #Search for a Book
                num = bookSearch(library)
                
                puts "No results found" if num == 0
                puts
            elsif option == 5 #Add Books
                continue = true
                
                puts "-------------Add Books-------------"
                puts
                
                while continue
                    add = {}
                    
                    print "Title: "
                    add["title"] = gets.chomp
                    print "Author: "
                    add["author"] = gets.chomp
                    print "ISBN: "
                    add["isbn"] = gets.to_i
                    
                    r = library.addBook(add)
                    puts "-------------------------------"
                    
                    puts "ERROR! #{r["error"]}" if r.has_key?("error")
                    library.searchBook( {"isbn" => add["isbn"]} ) if r["success"] == true
                    
                    puts
                    print "Would you like to add another book (y for yes)? "
                    continue = gets.chomp == "y"
                    puts
                end
            elsif option == 6 #Modify A Book
                puts  "-------------Modify A Book-------------"
                puts  "NOTE: Leaving a field blank will keep the old value"
                puts
                
                print "Enter the ISBN of the book you wish to modify: "
                isbn = gets.to_i
                
                library.searchBook( {"isbn" => isbn} )
                
                params = {}
                print "New Title: "
                params["title"] = gets.chomp
                print "New Author: "
                params["author"] = gets.chomp
                print "New Status: "
                params["status"] = gets.chomp
                
                library.updateBook(isbn, params)
                
                library.searchBook( {"isbn" => isbn} )
                puts
            elsif option == 7 #Delete Book
                puts  "-------------Delete Book-------------"
                puts
                
                print "Enter the ISBN of the book to delete: "
                isbn = gets.to_i
                
                library.searchBook({"isbn" => isbn})
                
                print "Are you sure you want to delete this book (y for yes)? "
                remove = gets.chomp == "y"
                
                puts
                if remove
                    r = library.removeBook(isbn)
                    puts "Book successfully removed" if r["success"] = true
                    puts "ERROR! #{r["error"]}"  if r.has_key?("error")
                end
                puts
            elsif option == 8 #Manage Requests
                requests.view
                puts
                
                print "Delete a request (y for yes)? "
                
                if gets.chomp == "y"
                    puts
                    print "Enter the number of the request you wish to delete: "
                    
                    if requests.delete(gets.to_i)
                        puts "Request successfully deleted"
                    else
                        puts "Error deleted request"
                    end
                    
                    puts
                end
            elsif option == 9 #Add User
                puts  "-------------Add User-------------"
                puts
                
                params = {}
                
                print "Username: "
                params["username"] = gets.chomp
                print "Password: "
                params["password"] = gets.chomp
                print "First Name: "
                params["firstName"] = gets.chomp
                print "Last Name: "
                params["lastName"] = gets.chomp
                print "Is #{} an admin (y for yes)? "
                params["admin"] = gets.chomp == "y"
                
                success = users.addUser(params)
                puts "#{params["firstName"]} was successfully added" if success
                puts "Something went wrong adding new user" if not success
                puts
            end
            option = getAdminOption
        end
    else #User
        option = getUserOption
        
        while not option == 0
            if option == 1 #List Books
                num = library.searchBook
                
                puts "There are currently no books in the library" if num == 0
                puts
            elsif option == 2 #List Available Books
                num = library.searchBook( {"status" => "available"} )
                
                puts "There are currently no books available" if num == 0
                puts
            elsif option == 3 #Search For Book
                num = bookSearch(library)
                
                puts "No results found" if num == 0
                puts
            elsif option == 4 #View Your Books
                num = library.listCheckedOutBooks(users, user.id)
                
                puts "You currently have no books checked out" if num == 0
                puts
            elsif option == 5 #Request Book
                request = Requests.new($database)
                
                puts  "-------------Request A Book-------------"
                puts
                
                params = {}
                
                print "Title: "
                params["title"] = gets.chomp
                print "Author: "
                params["author"] = gets.chomp
                
                success = request.requestBook(user.id, params)
                
                puts "#{params["title"]} by #{params["author"]} was successfully requested" if success
                puts "Something went wrong with the requst" if not success
            elsif option == 6 #Checkout Book
                print "Enter the ISBN of the book you wish to check out: "
                isbn = gets.to_i
                
                library.checkOutBook(isbn, user.id)
            elsif option == 7 #Return Book
                print "Enter ISBN of book you are returning: "
                isbn = gets.to_i
                
                library.checkInBook(isbn)
            end
            option = getUserOption
        end
    end
    
    continue = welcome
end

puts
puts "Thank you for using the Library Management System."
puts "Have a Wonderful Day!"
