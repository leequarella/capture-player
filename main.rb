# Load the gem
require 'game-client'
require 'pry'

# Setup authorization
GameClient.configure do |config|
  # Configure Bearer authorization: token
  config.host = 'http://td-capture-the-flag.herokuapp.com' # https://example.com
  config.access_token = 'lee@testdouble.com' # alice@example.com
end

$api_instance = GameClient::GameApi.new

$directions = {
  h: "home",
  n: "north",
  s: "south",
  e: "east",
  w: "west"
}

$modes = {
  move: :move,
  comb: :comb
}

$mode = :move
$player = nil

def change_mode
  puts "mode?"
  m = gets
  m.chomp!
  desired_mode = $modes[m.to_sym]
  if desired_mode
    $mode = desired_mode
  end
end

def action_input
  case $mode
  when :move
    direction_input
  when :comb
    comb
  else
    change_mode
  end
end

def comb
  puts "combing"
  record($api_instance.get_player)
  move_to_root
  sweep_for_flag
end

def column_move(direction)
  40.times do |i|
    puts "column_move #{direction} #{i}. mode: #{$mode}"
    record($api_instance.post_moves(direction))
    return if $mode == :move
    sleep 0.1
  end
end

def sweep_for_flag
  column_move("south")
  return if $mode == :move

  record($api_instance.post_moves("east"))

  column_move("north")
  return if $mode == :move

  record($api_instance.post_moves("east"))

  column_move("south")
  return if $mode == :move

  record($api_instance.post_moves("east"))

  column_move("north")
  return if $mode == :move

  record($api_instance.post_moves("east"))

  column_move("south")
  return if $mode == :move
end

def move_to_root
  dist_to_x = $player.x
  dist_to_y = $player.y

  puts "dist_to_x #{dist_to_x}"
  puts "dist_to_y #{dist_to_y}"
  dist_to_x.times do |i|
    puts "going to x 0 #{i}"
    record($api_instance.post_moves("west"))
    sleep 0.1
  end

  dist_to_y.times do |i|
    puts "going to y 0 #{i}"
    record($api_instance.post_moves("north"))
    sleep 0.1
  end
end

def go_home
  $mode = :home
  dist_to_x = 40 - $player.x

  if dist_to_x.positive?
    (dist_to_x + 4).times do |i|
      puts "homing #{i}"
      record($api_instance.post_moves("east"))
      sleep 0.1
    end
  end
  $mode = :move
end

def direction_input
  puts "Direction?"
  d = gets
  d.chomp!
  if d == "mode"
    change_mode
    return
  end
  direction = $directions[d.to_sym]
  if direction
    if direction == "home"
      puts "GOING HOME!!!"
      go_home
    else
      puts "moving #{direction}"
      result = $api_instance.post_moves(direction)
      record(result)
      pp result
    end
  else
    puts "no direction"
  end
end

def record(result)
  $player = result.player

  if $player.has_flag
    puts "YOU HAVE THE FLAGGGG!!"
    $mode = :move
  end
end

record($api_instance.get_player)
while true
  begin
    action_input
  rescue GameClient::ApiError => e
    puts "Exception when calling GameApi->get_player: #{e}"
  end
end
