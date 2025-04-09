require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

#Admin admin123
#Sebastian sebbe123

#Gör så att användaren kan välja att visa secret achievements

#Fixa med Yardoc innan inlämning

#Lista all spel när du create achievement

get('/')  do
    slim(:register)
end

get('/users') do
    db = SQLite3::Database.new("db/DB.db")
    db.results_as_hash = true
    users = db.execute("SELECT * FROM users")
    slim(:"users/index", locals:{users:users})
end

post('/users/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/DB.db")
    db.execute("DELETE FROM users WHERE UserId=?",id)
    redirect('/users')
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
        redirect('/showlogin')
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

    if result == nil
        redirect('/showlogin')
    end

    if BCrypt::Password.new(result["password_digest"]) == password
        session[:id] = result["UserId"]
        if session[:id] == 1
            redirect('/games')
        else
            redirect('/usergames')
        end
    else
        "WRONG PASSWORD"
    end
end

get('/showlogout') do
    slim(:logout)
end

post('/logout') do
    session[:id] = nil
    redirect('/')
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
    slim(:"games/show",locals:{result:result, result2:result2})
end

get('/achievements') do
    db = SQLite3::Database.new("db/DB.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM achievements")
    slim(:"achievements/index",locals:{achievements:result})
end

get('/achievements/new') do
    db = SQLite3::Database.new("db/DB.db")
    db.results_as_hash = true
    games = db.execute("SELECT * FROM games")
    slim(:"achievements/new", locals:{games:games})
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

get('/usergames') do
    id = session[:id].to_i
    db = SQLite3::Database.new("db/DB.db")
    db.results_as_hash = true
    user = db.execute("SELECT username FROM users WHERE UserId = ?", id).first
    result = db.execute("SELECT * FROM user_game_rel INNER JOIN games ON user_game_rel.game_id = games.GameId WHERE user_id = ?", id)
    no_game = db.execute("SELECT * FROM games WHERE GameId NOT IN (SELECT game_id FROM user_game_rel WHERE user_id = ?)", id)
    slim(:"usergames/index", locals:{user:user, result:result, no_game:no_game})
end

post('/usergames/new') do
    user_id = session[:id]
    game_id = params[:game_id]
    db = SQLite3::Database.new("db/DB.db")
    db.execute("INSERT INTO user_game_rel (user_id,game_id) VALUES (?,?)", [user_id, game_id])
    redirect('/usergames')
end

post('/usergames/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/DB.db")
    db.execute("DELETE FROM user_game_rel WHERE id =?",id)
    redirect('/usergames')
end

get('/usergames/:id') do
    game_id = params[:id]
    user_id = session[:id]
    db = SQLite3::Database.new("db/DB.db")
    db.results_as_hash = true
    game = db.execute("SELECT * FROM games WHERE GameId = ?", game_id).first
    result = db.execute("SELECT * FROM user_achievement_rel INNER JOIN achievements ON user_achievement_rel.achievement_id = achievements.AchievementId WHERE user_id = ? AND game_id = ?", [user_id, game_id])
    no_achievement = db.execute("SELECT * FROM achievements WHERE AchievementId NOT IN (SELECT achievement_id FROM user_achievement_rel WHERE user_id = ? AND game_id = ?) AND game_id = ?", [user_id, game_id, game_id])
    slim(:"usergames/show",locals:{game:game, result:result, no_achievement:no_achievement})
end

post('/usergames/:id/achievements/new') do
    game_id = params[:id].to_i
    user_id = session[:id]
    completed = params[:complete]
    db = SQLite3::Database.new("db/DB.db")

    if completed.class == Array
        completed.each do |achievement|
            db.execute("INSERT INTO user_achievement_rel (user_id, achievement_id) VALUES (?,?)", [user_id, achievement.to_i])
        end
    else
        db.execute("INSERT INTO user_achievement_rel (user_id, achievement_id) VALUES (?,?)", [user_id, completed.to_i])
    end

    redirect('/usergames')
end