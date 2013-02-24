require 'yaml'
require 'curses'
include Curses

#DIRECTIONS = RIGHT, DOWN, LEFT, UP
class Snake
  attr_accessor :eating
  def initialize
    @eating       = 0
    @portal_exist = false
  end
  
  def reset(pos_x, pos_y)
    @length       = 1
    @x            = pos_x
    @y            = pos_y
    @direction    = :right
    @portal_exist = false
    @body         = [ { :x => pos_x, :y => pos_y, :dir => @direction} ]    
  end
  
  def change_direction(key)
    case key
    when Key::RIGHT then @direction = :right  unless @direction == :left
    when Key::DOWN  then @direction = :down   unless @direction == :up
    when Key::LEFT  then @direction = :left   unless @direction == :right
    when Key::UP    then @direction = :up     unless @direction == :down
    end
    
  end
  
  def move
    case @direction
    when :right   then @x += 1
    when :down    then @y += 1
    when :left    then @x -= 1
    when :up      then @y -= 1
    end
    
    if collision('#')      
      setpos(1,5)
      message('OUCH!')
      if $game.lives > 1 then
        collide
      else
        $game.over
      end
      
    elsif collision('*')
      message('IT\'S PAINFUL!')
      if $game.lives > 1 then
        collide
      else
        $game.over
      end      
    
    elsif collision('@')
      $game.spawn_food
      @eating += 1
      
      if @eating % $game.bonus_rate[$game.level] == 0 and not $game.bonus_available
        $game.spawn_food("$")
        $game.duration = $game.bonus_duration[$game.level]
        $game.bonus_available = true
      end
      
      if @portal_exist == false and @eating >= $game.to_next_level[$game.level]
        $game.spawn_food(232.chr)
        @portal_exist = true
      end
      
      message('YUMMY!')
      $game.score += 1
      show
    
    elsif collision('+')
      warp
      delete_tail
      show
    
    elsif collision('$')
      message('DELICIOUS!')
      $game.score += $game.duration
      setpos(11,54)
      addstr(' '*(($game.duration/2).to_i + 1))
      $game.bonus_available = false
      show
    
    elsif collision(232.chr)
      if $game.level == 9 then
        $game.win
      else
        $game.level += 1
        reset($game.start_pos[$game.level][:x],$game.start_pos[$game.level][:y])
        $game.bonus_available = false
        $game.set_level
        $key = :right
        @eating = 0
      end
      
    else
      delete_tail
      show
    end
  end
  
  def message(string)
    setpos(1,5)
    addstr(' '*80)
    setpos(1,5)
    addstr(string)
  end
  
  def collision(char)
    setpos(@y, @x)
    obstacle = inch.chr
    if obstacle == char
      return true
    else 
      return false
    end
  end
  
  def collide
    $game.lives -= 1
    reset($game.start_pos[$game.level][:x],$game.start_pos[$game.level][:y])
    $game.bonus_available = false
    setpos(11,54)
    addstr(' '*(($game.duration/2).to_i + 1))
    $game.set_level
    $key = :right
  end

  def warp
    @y = 21 if @y == 3
    @y = 4  if @y == 22
    @x = 51 if @x == 5
    @x = 6  if @x == 52
  end
  
  def delete_tail
    tail = @body[0]
    @body.delete_at(0)
    setpos(tail[:y],tail[:x])
    delch
    insch(' ')
  end
  
  def show
    setpos(@y, @x);
    hash = { :x => @x, :y => @y, :dir => @direction}
    @body << hash
    addstr('*')
    refresh
  end
end

class Game
  attr_accessor :map, :lives, :score, :level, :speed, :duration, :bonus_available, :start_pos
  attr_accessor :to_next_level, :bonus_rate, :bonus_duration
  def initialize
    @lives      = 5
    @score      = 0
    @level      = 0
    @speed      = 0.12
    @duration   = -1
    @lose       = false
    @winning    = false
    @start_pos  = [ 
                   {:x => 11, :y => 13},
                   {:x => 11, :y => 12},
                   {:x =>  8, :y => 12},
                   {:x =>  7, :y => 11},
                   {:x => 21, :y => 13},
                   {:x => 21, :y => 12},
                   {:x => 17, :y => 12},
                   {:x => 21, :y => 12},
                   {:x => 11, :y => 12},
                   {:x =>  7, :y => 13},
                  ]
    @to_next_level     = [30,30,20,30,30,30,30,30,30,20]
    @bonus_rate        = [4,5,6,7,8,9,10,11,12,13]
    @bonus_duration    = [15,20,25,30,35,40,45,50,55,60]
    @bonus_available   = false
  end
  
  def main_menu
    cls
    title = <<heredoc
**      **  **                
**      **  **                
**      **  **                
**      **  **                
**      **  **    ***   ***** 
**      **  **  ******  ******
**      **  **  **   ** **   *
**      **  **  ******  **    
**      **  **  *****   **    
***    ***  **  **    * **    
 ********   **  ******* **    
   ****      **   ***   **    
heredoc
    title = title.split("\n")
    for i in (0..11)
      setpos(3+i,27)
      addstr(title[i])
    end
    setpos(19,36)
    addstr("Adventure")
    setpos(20,36)
    addstr("High Scores")
    setpos(21,36)
    addstr("Settings")
    setpos(22,36)
    addstr("Help")
    setpos(23,36)
    addstr("Exit")
    pos = 19
    setpos(pos, 34)
    addstr('*')
    load_highscore
    while true
      $key = getch
      if $key == "Q" then
        exit
      end
      case $key
      when 10 then
        case pos
        when 19 then
          $mode = :arcade
          new_arcade
          break
        when 20 then
          show_highscore
        when 21 then
          settings
        when 22 then
          help
        when 23 then
          exit
        end
      when Key::DOWN then
        setpos(pos, 34)
        addstr(' ')
        pos += 1 if pos < 23

      when Key::UP   then
        setpos(pos, 34)
        addstr(' ')
        pos -= 1 if pos > 19
      end
      setpos(pos, 34)
      addstr('*')
    end    
  end

  def settings
    cls
    setpos(17,36)
    addstr('Speed Setting')
    setpos(19,36)
    addstr('1. Snaily')
    setpos(20,36)
    addstr('2. Wormy')
    setpos(21,36)
    addstr('3. Eely')
    setpos(22,36)
    addstr('4. Snakey')
    setpos(23,36)
    addstr('5. Lightning Stinger')
    pos = 19
    setpos(19,34)
    addstr('*')
    while true
      $key = getch
      case $key
      when 10 then
        case pos
        when 19 then @speed = 0.33
        when 20 then @speed = 0.26
        when 21 then @speed = 0.19
        when 22 then @speed = 0.12
        when 23 then @speed = 0.07
        end
        main_menu
      when Key::UP then 
        setpos(pos, 34)
        addstr(' ')
        pos -= 1 if pos > 19
      when Key::DOWN then
        setpos(pos, 34)
        addstr(' ')
        pos += 1 if pos < 23
      end
      setpos(pos, 34)
      addstr('*')
    end
  end
  def new_arcade
    if $mode == :arcade then
      cls
      load_map
      set_level
      
      player   = Snake.new
      player.reset(@start_pos[@level][:x],@start_pos[@level][:y])
      
      thread = repeat_every(@speed) do
        if @lose == true then
          Thread.kill(thread)
          exit
        end
        statistics
      
        @duration -= 1 if @bonus_available

        if @duration == 0
          setpos(@bonus_y, @bonus_x)
          ch = inch.chr
          addstr(' ') if ch == '$'
          @duration = -1
          @bonus_available = false
        end
        
        player.change_direction($key)
        player.move
      end
      
      while true
        $key = getch
        if $key == "Q" then
          exit
        end
        
      end
      thread.join
    end
  end
  
  def load_highscore
    f     = File.open('highscore.yml')
    @highscore = YAML.load(f)
    f.close
  end
  
  def show_highscore
    cls
title = <<heredoc
                              ***                              
*    *        *  *           *   *  *****                      
*    *        *  *           *      *                          
*    *  ***   *  *      ***  *      *     ***   ********   **  
*    * *   *  *  *     *   * ***    **** *   *  *   *   * *  * 
******   ***  *  *     *   * *      *      ***  *   *   * *  **
*    *  *  *  *  *     *   * *      *     *  *  *   *   * ***  
*    * **  *  *  *     *   * *      *    **  *  *   *   * *   *
*    *   ***  ** **     ***  *      *      ***  *   *   *  *** 
heredoc
    title = title.split("\n")
    for i in (0..8)
      setpos(1+i,9)
      addstr(title[i])
    end
    setpos(12,28)
    addstr("Score")
    setpos(12,34)
    addstr("Level")
    setpos(12,40)
    addstr("Winner")
    setpos(12,48)
    addstr("Name")
    for i in (0..9)
      setpos(14+i,29)
      addstr(@highscore[i][0].to_s)
      setpos(14+i,36)
      addstr(@highscore[i][1].to_s)
      setpos(14+i,41)
      addstr(@highscore[i][2].to_s)
      setpos(14+i,48)
      addstr(@highscore[i][3])
    end
    getch
    main_menu if not @lose
    exit
  end
  
  def help
    cls
    setpos(12,30)
    addstr("Created by : irfan3")
    setpos(14,26)
    addstr("www.github.com/irfan3studio")
    getch
    main_menu
  end

  def load_map
    f     = File.open('map.yml')
    @map  = YAML.load(f)
    f.close
  end
  
  def set_level
    for i in 0...20
      setpos(3+i,5)
      addstr(@map[@level][1][i])
    end
    spawn_food
  end
  
  def spawn_food(char = '@')
    x = 0; y = 0
    success_spawn = false
    while not success_spawn
      x = Random.rand(6..51)
      y = Random.rand(4..21)
      setpos(y, x)
      ch = inch.chr
      success_spawn = true if ch == ' '
    end
    setpos(y, x)
    addstr(char)
    if char == '$'
      @bonus_x = x
      @bonus_y = y
    end
  end
  
  def statistics
    setpos(3, 56)
    addstr("Level : "+(@level+1).to_s)
    setpos(4, 56)
    addstr(' '*20)
    setpos(4, 56)
    addstr(@map[@level][0])
    setpos(8, 56)
    addstr("Live  : "+@lives.to_s)
    setpos(9, 56)
    addstr("Score : "+@score.to_s)
    
    if @bonus_available
      setpos(11,54)
      addstr(' '*((@duration/2).to_i + 1))
      setpos(11,54)
      addstr(219.chr*(@duration/2).to_i)
    end
  end
  
  def over
    cls
    setpos(12,35)
    addstr('Game Over')
    getch
    @lose     = true
    @winning  = false
    save_menu if @score >= @highscore[9][0]
    show_highscore
  end
  
  def save_menu
    close_screen
    system('cls')
    puts "\n"*3
    puts " "*25 + "What\'s your name?"
    print " "*30
    name = gets.chomp
    init_screen
    noecho
    curs_set(0)
    doupdate
    @highscore.pop
    @highscore << [@score, @level+1, @winning, name]
    save
  end
  
  def save
    @highscore.sort!
    @highscore.reverse!
    f = File.new('highscore.yml', 'w')
    f.write(@highscore.to_yaml)
    f.close
    show_highscore
  end
  
  def win
    cls
    setpos(12,35)
    addstr("Congratulations!")
    setpos(13,25)
    addstr("You have won this game with a score of #{$game.score}")
    @lose     = true
    @winning  = true
    save_menu if @score >= @highscore[9][0]
  end
  
  def cls
    clear
  end
end

def repeat_every(interval)
  Thread.new do
    loop do
      start_time = Time.now
      yield
      elapsed = Time.now - start_time
      sleep([interval - elapsed, 0].max)
    end
  end
end

init_screen
noecho
stdscr.keypad(true)
curs_set(0)
$mode    = :menu
$game    = Game.new
$game.main_menu