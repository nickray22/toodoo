require "toodoo/version"
require "toodoo/init_db"
require 'highline/import'
require 'pry'
require 'date'

module Toodoo
  class User < ActiveRecord::Base
    has_many :TodoList
  end

  class TodoList < ActiveRecord::Base
    has_many :TodoItems
    belongs_to :User
  end

  class TodoItem < ActiveRecord::Base
    belongs_to :TodoList
  end
end  

class TooDooApp
  def initialize
    @user = nil
    @todos = nil
    @show_done = nil
  end

  def new_user
    say("Creating a new user:")
    name = ask("Username?") { |q| q.validate = /\A[\w\s]+\Z/ }
    @user = Toodoo::User.create(:name => name)
    say("We've created your account and logged you in. Thanks #{@user.name}!")
  end

  def login
    choose do |menu|
      menu.prompt = "Please choose an account: "
      Toodoo::User.find_each do |u|
        menu.choice(u.name, "Login as #{u.name}.") { @user = u }
      end
      menu.choice(:back, "Just kidding, back to main menu!") do
        say "You got it!"
        @user = nil
      end
    end
  end

  def delete_user
    choices = 'yn'
    delete = ask("Are you *sure* you want to stop using TooDoo?") do |q|
      q.validate =/\A[#{choices}]\Z/
      q.character = true
      q.confirm = true
    end
    if delete == 'y'
      @user.destroy
      @user = nil
    end
  end

  def new_todo_list
    # This should create a new todo list by getting input from the user.
    # The user should not have to tell you their id.
    # Create the todo list in the database and update the @todos variable.
    say("Creating a new To-Do List:")
    title = ask("To-Do List Title?") { |q| q.validate = /\A[\w\s]+\Z/ }
    @todos = Toodoo::TodoList.create(:title => title, :user_id => @user.id)
    say("Your To-Do List has been created with the title: #{@todos.title}, for the user: #{@user.name}.")
  end

  def pick_todo_list
    choose do |menu|
      # This should get get the todo lists for the logged in user (@user).
      # Iterate over them and add a menu.choice line as seen under the login method's
      # find_each call. The menu choice block should set @todos to the todo list.
      menu.prompt = "Please choose a list: "
      Toodoo::TodoList.where(:user_id => @user.id).find_each do |l|
        menu.choice(l.title, "Choose the list titled: #{l.title}.") { @todos = l }
      end
      menu.choice(:back, "Just kidding, back to the main menu!") do
        say "You got it!"
        @todos = nil
      end
    end
  end

  def delete_todo_list
    # This should confirm that the user wants to delete the todo list.
    # If they do, it should destroy the current todo list and set @todos to nil.
    pick_todo_list
    choices = 'yn'
    delete = ask("Are you *sure* you want to delete this To-Do List?") do |q|
      q.validate =/\A[#{choices}]\Z/
      q.character = true
      q.confirm = true
    end
    if delete == 'y'
      @todos.destroy
      @todos = nil
    end
  end

  def new_task
    # This should create a new task on the current user's todo list.
    # It must take any necessary input from the user. A due date is optional.
    say("Creating a new Task:")
    choices = 'yn'
    name = ask("#{@todos.title} List Task Name?") { |q| q.validate = /\A[\w\s]+\Z/ }
    due_question = ask("Would you like to add a due-date for the task #{name}?") do |q|
      q.validate =/\A[#{choices}]\Z/
      q.character = true
    end
    if due_question == 'y'
      due = ask('To-Do List Task Due Date?', Date) do |q|
        #q.default = DateTime.now.strftime('%m-%d-%Y')
        #q.validate = lambda { |d| binding.pry ; Date.parse((Date.strptime(d, '%m-%d-%Y')).to_s) >= Date.today }
        q.default = Date.today.to_s
        q.validate = lambda { |d| Date.parse(d) >= Date.today }
        q.responses[:not_valid] = "Please enter a valid date that is greater than or equal to today's date"
      end
      task = Toodoo::TodoItem.create(:name => name, :due_date => due, :item_id => @todos.id, :finished => false)
      say("Your To-Do List Task has been created with the name: #{task.name}, for the list: #{@todos.title}, of the user: #{@user.name}.")
      say("Your Task has a Due-Date of: #{task.due_date}")
      task.save
    else
      task = Toodoo::TodoItem.create(:name => name, :item_id => @todos.id, :finished => false)
      say("Your To-Do List Task has been created with the name #{task.name}, for the list: #{@todos.title}, of the user: #{@user.name}.")
      task.save
    end
  end

  # For the next 3 methods, make sure the change is saved to the database.
  def mark_done
    # This should display the todos on the current list in a menu
    # similarly to pick_todo_list. Once they select a todo, the menu choice block
    # should update the todo to be completed.
    choose do |menu|
      menu.prompt = "Please choose a task to mark as complete: "
      Toodoo::TodoItem.where(:item_id => @todos.id, :finished => false).find_each do |i|
        menu.choice(i.name, "Mark the task under the name #{i.name}.") { 
          i.finished = true
          say("The task under: #{i.name} is now marked as complete.")
          i.save
        }
      end
      menu.choice(:back, "Just kidding, back to the main menu!") do
        say "You got it!"
      end
    end
  end

  def change_due_date
    # This should display the todos on the current list in a menu
    # similarly to pick_todo_list. Once they select a todo, the menu choice block
    # should update the due date for the todo. You probably want to use
    # `ask("foo", Date)` here.
    choose do |menu|
      menu.prompt = "Please choose a task for which to edit the due date: "
      Toodoo::TodoItem.where(:item_id => @todos.id, :finished => false).find_each do |i|
        menu.choice(i.name, "Choose the task under the name #{i.name}.") {
          due = ask('To-Do List Task Due Date?') do |q|
            q.validate = lambda { |d| Date.parse(d) >= Date.today }
            q.responses[:not_valid] = "Please enter a valid date that is greater than or equal to today's date"
          end
          i.due_date = due
          say("The task under: #{i.name} has had its due date changed to: #{due}.")
          i.save
        }
      end
      menu.choice(:back, "Just kidding, back to the main menu!") do
        say "You got it!"
      end
    end
  end

  def edit_task
    # This should display the todos on the current list in a menu
    # similarly to pick_todo_list. Once they select a todo, the menu choice block
    # should change the name of the todo.
    choose do |menu|
      menu.prompt = 'Please choose a task for which to edit the name:'
      Toodoo::TodoItem.where(:item_id => @todos.id).find_each do |i|
        menu.choice(i.name, "Choose the task under #{i.name}.") {
          name = ask("#{@todos.title} List Task New Name?") { |q| q.validate = /\A[\w\s]+\Z/ }
          i.name = name
          say("The task name has been changed to: #{i.name}")
          i.save
        }
      end
      menu.choice(:back, 'Just kidding, back to the main menu!') do
        say('You got it!')
      end
    end
  end

  def show_overdue
    # This should print a sorted list of todos with a due date *older*
    # than `Date.now`. They should be formatted as follows:
    # "Date -- Eat a Cookie"
    # "Older Date -- Play with Puppies"
    pick_todo_list
    date = Date.today
    Toodoo::TodoItem.where(:item_id => @todos.id, :finished => false).group('due_date').having("due_date > #{date}").order('due_date asc').each do |obj|
      say("#{obj.due_date.to_s} -- #{obj.name}")
    end
  end

  def run
    puts "Welcome to your personal TooDoo app."
    loop do
      choose do |menu|
        menu.layout = :menu_only
        menu.shell = true

        # Are we logged in yet?
        unless @user
          menu.choice(:new_user, "Create a new user.") { new_user }
          menu.choice(:login, "Login with an existing account.") { login }
        end

        # We're logged in. Do we have a todo list to work on?
        if @user && !@todos
          menu.choice(:delete_account, "Delete the current user account.") { delete_user }
          menu.choice(:new_list, "Create a new todo list.") { new_todo_list }
          menu.choice(:pick_list, "Work on an existing list.") { pick_todo_list }
          menu.choice(:remove_list, "Delete a todo list.") { delete_todo_list }
        end

        # Let's work on some todos!
        if @todos
          menu.choice(:new_task, "Add a new task.") { new_task }
          menu.choice(:mark_done, "Mark a task finished.") { mark_done }
          menu.choice(:move_date, "Change a task's due date.") { change_due_date }
          menu.choice(:edit_task, "Update a task's description.") { edit_task }
          menu.choice(:show_done, "Toggle display of tasks you've finished.") { @show_done = !!@show_done }
          menu.choice(:show_overdue, "Show a list of task's that are overdue, oldest first.") { show_overdue }
          menu.choice(:back, "Go work on another Toodoo list!") do
            say "You got it!"
            @todos = nil
          end
        end

        menu.choice(:quit, "Quit!") { exit }
      end
    end
  end
end

todos = TooDooApp.new
todos.new_user
todos.new_todo_list
todos.new_task
todos.new_task
todos.new_task
binding.pry

#todos = TooDooApp.new
#todos.run
