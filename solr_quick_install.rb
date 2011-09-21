#!/usr/bin/env ruby

require 'Open3'
require 'fileutils'

class Solr_quick_install
  attr_accessor :desktop_dir_full_path, :solr_source, :solr_app_dir
  
  def initialize
    @desktop_dir_full_path = `cd ~/Desktop && pwd`; @desktop_dir_full_path.chomp!
    @solr_source = "http://www.fightrice.com/mirrors/apache//lucene/solr/3.4.0/apache-solr-3.4.0.zip"
    # do you have java installed?
    unless java?
      puts "You do not have java installed, or it is not in your path."
      exit
    end
    
    # Is it java version 6?
    unless java6?
      puts "You have java installed, but it's not the right version."
      exit
    end
    # make a project directory somewhere easy
    unless create_project
      puts "We had a little problem setting up your project."
      exit
    end
    
    # download the solr project from apache into that directory
    unless get_source
      puts "Darn, we can't get the source code for some reason."
      exit
    end
    
    # run the example app and open a browser to the specified address and port
    unless run_solr
      puts "Having trouble launching the solr app."
      exit
    end
    exit
  end
  
private
  
  def java?
    begin
      java = `which java`
    rescue
      return false
    end
    
    case
      when java.empty?; return false
      when java.include?("java"); return true
      else; return false
    end
  end
  
  def java6?
    version_call = "java -version"
    
    stdin, stdout, stderr = Open3.popen3(version_call)
    
    version = stderr.gets
    
    case 
      when version.empty?; return false
      when version.include?("1.6"); return true
      else; return false
    end
  end
  
  def create_project
    #go to the desktop
    begin
      Dir.chdir(@desktop_dir_full_path)
    rescue
      return false
    end
    #make the project folders inside
    dirs = ["solr", "solr/source", "solr/download"]
    
    dirs.each do |dir|
      
      begin
        Dir.mkdir(dir)
      rescue Errno::EEXIST
        #don't do anything, the file is already there
      end
      
    end
    
    return true
  end
  
  def get_source
    dl_zip = "solr_dl.zip" #just adding a static name for our resulting download file without junk and versions attached to it
    dest_unzip_file = @desktop_dir_full_path + "/solr/source/solr"
    #change to the download dir
    Dir.chdir(@desktop_dir_full_path + "/solr/download")
    @solr_app_dir = @desktop_dir_full_path + '/solr/source/solr/apache-solr-3.4.0'
    
    #is there an unzipped file ready to use? if so, sweet!
    if File.exist?(dest_unzip_file) then return true; end
    
    #did we already try to dl there before, or can we save some network trsfr time here by NOT dl again?
    unless File.exist?(dl_zip)
      #curl that apache solr wonderfulness right in there!
      cmd = "curl -o #{dl_zip} #{@solr_source}"
      begin
        %x[#{cmd}]
      rescue
        return false
      end
      
    end
    
    #unzip that bad boy, get 'er done
    puts "Unzipping..."
    unzip = "unzip -q #{dl_zip} -d #{dest_unzip_file}"
    begin
      stdin, stdout, stderr = Open3.popen3(unzip)
    rescue
      return false
    end
    
    # got an error on that unzip command
    unless stderr.gets.nil?; return false end
    
    return true
  end
  
  def run_solr
    Dir.chdir(@solr_app_dir + '/example')
    puts 'Starting solr example app... CTRL-C to quit'
    task_list = ["java -jar start.jar", "open http://localhost:8983/solr/admin/"]
    begin
      spawn 'java -jar start.jar'
      sleep 3; spawn 'open http://localhost:8983/solr/admin/'
      Process.waitall
      return true
    rescue
      return false
    end
    return true
  end
end
solr_quick_install = Solr_quick_install.new