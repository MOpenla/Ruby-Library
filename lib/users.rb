require 'sqlite3'

class Users
    def initialize(file)
        @users = SQLite3::Database.new(file)
    end
    
    def validLogin?(login)
        valid = false
        
        @users.execute("SELECT username FROM logins") do |user|
            if user[0] == login
                valid = true
            end
        end
        
        valid
    end
    
    def getID(user)
        id = -1
        
        @users.execute("SELECT userID FROM logins WHERE username = ?", user) do |x|
            id = x[0]
        end
        id
    end
    
    def getName(id)
        name = ""
        
        @users.execute("SELECT firstName, lastName FROM profiles WHERE userID = ?", id) do |x|
            name = "#{x[0]} #{x[1]}"
        end
        
        name
    end
    
    def addUser(params)
        successful = false
        
        usrID = 1
        date = Time.now.strftime("%Y%m%d").to_i
        
        @users.execute("SELECT userID FROM logins ORDER BY userID DESC LIMIT 1") do |x|
            usrID += x[0]
        end
        
        @users.execute("
            INSERT INTO logins
            VALUES (?, ?, ?)",
            usrID,
            params["username"],
            params["password"]
        )
        
        @users.execute("
            INSERT INTO profiles
            VALUES (?, ?, ?, ?, ?)",
            usrID,
            params["firstName"],
            params["lastName"],
            date,
            params["admin"]
        )
        
        successful = true
        successful
    end
end

class Profile
    attr_accessor :id, :fName, :lName, :dateJoined, :isAdmin
    
    def initialize(file, id)       
        db = SQLite3::Database.new(file)
        
        db.execute("SELECT * FROM profiles WHERE userID = ? LIMIT 1", id) do |x|
            @id         = x[0]
            @fName      = x[1]
            @lName      = x[2]
            @dateJoined = x[3]
            @isAdmin    = x[4] == "true"
        end
    end
end
