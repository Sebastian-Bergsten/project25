require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

#11:49 sista to do filmen

get('/')  do
    slim(:register)
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    email = params[:email]
    db = SQLite3::Database.new("db/DB.db")

    if password == password_confirm
        password_digest = BCrypt::Password.create(password)
        db.execute("INSERT INTO users (username, password_digest, email) VALUES (?,?,?)",[username, password_digest, email])
        redirect('/')
    else
        "YOUR PASSWORDS DON'T MATCH"
    end
end

get('/showlogin') do
    slim(:login)
end

post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new("db/DB.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first

    if BCrypt::Password.new(result["password_digest"]) == password
        redirect('/games')
    else
        "WRONG PASSWORD"
    end
end

get('/games') do
    db = SQLite3::Database.new("db/DB.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM games")
    slim(:"games/index",locals:{games:result})
end

get('/games/new') do
    slim(:"games/new")
end

post('/games/new') do
    title = params[:title]
    db = SQLite3::Database.new("db/DB.db")
    db.execute("INSERT INTO games (title) VALUES (?)",title)
    redirect('/games')
end

get('/games/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/DB.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM games WHERE GameId = ?",id).first
    result2 = db.execute("SELECT title FROM achievements WHERE game_id=?",id)
    slim(:"games/show",locals:{result:result,result2:result2})
end

get('/achievements') do
    db = SQLite3::Database.new("db/DB.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM achievements")
    slim(:"achievements/index",locals:{achievements:result})
end

get('/achievements/new') do
    slim(:"achievements/new")
end

post('/achievements/new') do
    "procent = params[:procent].to_i"
    title = params[:title]
    details = params[:details]
    link = params[:link]
    hidden_attribute = params[:hidden_attribute].to_i
    game_id = params[:game_id].to_i
    db = SQLite3::Database.new("db/DB.db")
    db.execute("INSERT INTO achievements (title, details, link, hidden_attribute, game_id) VALUES (?,?,?,?,?)",[title,details,link,hidden_attribute,game_id])
    redirect('/achievements')
end

post('/achievements/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/DB.db")
    db.execute("DELETE FROM achievements WHERE AchievementId=?",id)
    redirect('/achievements')
end

post('/achievements/:id/update') do
    id = params[:id].to_i
    title = params[:title]
    details = params[:details]
    link = params[:link]
    hidden_attribute = params[:hidden_attribute].to_i
    game_id = params[:game_id].to_i
    db = SQLite3::Database.new("db/DB.db")
    db.execute("UPDATE achievements SET title=?, details=?, link=?, hidden_attribute=?, game_id=? WHERE AchievementId=? ",[title,details,link,hidden_attribute,game_id,id])
    redirect('/achievements')
end

get('/achievements/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/DB.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM achievements WHERE AchievementId = ?",id).first
    slim(:"/achievements/edit", locals:{result:result})
end

get('/achievements/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/DB.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM achievements WHERE AchievementId = ?",id).first
    result2 = db.execute("SELECT title FROM games WHERE GameId IN (SELECT game_id FROM achievements WHERE AchievementId = ?)",id).first
    slim(:"achievements/show",locals:{result:result,result2:result2})
end