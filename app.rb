require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
#require 'becrypt'

# fyra minuter in på film 4

enable :sessions

get('/')  do
    slim(:start)
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
    title = params[:title]
    game_id = params[:game_id].to_i
    db = SQLite3::Database.new("db/DB.db")
    db.execute("INSERT INTO achievements (title, game_id) VALUES (?,?)",[title,game_id])
    redirect('achievements')
end


get('/achievements/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/DB.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM achievements WHERE AchievementId = ?",id).first
    result2 = db.execute("SELECT title FROM games WHERE GameId IN (SELECT game_id FROM achievements WHERE AchievementId = ?)",id).first
    slim(:"achievements/show",locals:{result:result,result2:result2})
end