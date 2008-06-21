$:.unshift File.dirname(__FILE__)
%w(rubygems git tempfile fileutils yaml wrap).each {|f| require f}

module Chit
  extend self
  VERSION = '0.0.4'
  
  defaults = {
    'root'  => File.join("#{ENV['HOME']}",".chit")
  }
  
  CHITRC = File.join("#{ENV['HOME']}",".chitrc")
  
  FileUtils.cp(File.join(File.dirname(__FILE__), "..","resources","chitrc"), CHITRC) unless File.exist?(CHITRC)
  
  CONFIG = defaults.merge(YAML.load_file(CHITRC))
  
  def run(args)
    unless File.exist?(main_path) && File.exist?(private_path)
      return unless init_chit
    end
    args = args.dup
    
    return unless parse_args(args)

    if %w[sheets all].include? @sheet
      return list_all()
    end
    
    unless File.exist?(sheet_file)
      update
    end
    
    unless File.exist?(sheet_file)
      if args.delete('--no-add').nil? && CONFIG['add_if_not_exist']
        add(sheet_file)
      else
        puts "Error!:\n  #{@sheet} not found"
        puts "Possible sheets:"
        search_title
      end
    else
      show(sheet_file)
    end
  end
  
  def parse_args(args)
    init_chit and return if args.delete('--init')
    update and return if args.delete('--update')
    
    @sheet = args.shift || 'chit'
    is_private = (@sheet =~ /^@(.*)/)
    @sheet = is_private ? $1 : @sheet

    working_dir = is_private ? private_path : main_path
    @git = Git.open(working_dir)

    @fullpath = File.join(working_dir, "#{@sheet}.yml")
    
    add(sheet_file) and return if (args.delete('--add')||args.delete('-a'))
    edit(sheet_file) and return if (args.delete('--edit')||args.delete('-e'))
    search_title and return if (args.delete('--find')||args.delete('-f'))
    search_content and return if (args.delete('--search')||args.delete('-s'))
    true
  end
  
  def list_all
    puts all_sheets.sort.join("\n")
  end
  
  def search_content
    @git.grep(@sheet).each {|file, lines|
      title = title_of_file(file.split(':')[1])
      lines.each {|l|
        puts "#{title}:#{l[0]}:  #{l[1]}"
      }
    }
  end
  
  def search_title
    reg = Regexp.compile("^#{@sheet}")
    files = all_sheets.select {|sheet| sheet =~ reg }
    puts files.sort.join("\n")
    true
  end
  
  def sheet_file
    @fullpath
  end
  
  def init_chit
    FileUtils.mkdir_p(CONFIG['root'])
    if CONFIG['main']['clone-from']
      if File.exist?(main_path)
        puts "Main chit has already been initialized."
      else
        puts "Initialize main chit from #{CONFIG['main']['clone-from']} to #{CONFIG['root']}/main"
        Git.clone(CONFIG['main']['clone-from'], 'main', :path => CONFIG['root'])
        puts "Main chit initialized."        
      end
    else
      puts "ERROR: configuration for main chit repository is missing!"
      return
    end
    
    unless File.exist?(private_path)
      if CONFIG['private'] && CONFIG['private']['clone-from']
        puts "Initialize private chit from #{CONFIG['private']['clone-from']} to #{CONFIG['root']}/private"
        Git.clone(CONFIG['private']['clone-from'], 'private', :path => CONFIG['root'])
        puts "Private chit initialized."
      else
        puts "Initialize private chit from scratch to #{CONFIG['root']}/private"
        Git.init(private_path)
        puts "Private chit initialized."
      end
    else
      puts "Private chit has already been initialized."
    end
    puts "Chit init done."
    true
  end
  
  def update
    if CONFIG['main']['clone-from']
      g = Git.open(main_path)
      g.pull
    end
  rescue
    puts "ERROR: can not update main chit."
    puts $!
  end
  
  def main_path
    File.join(CONFIG['root'], 'main')
  end
  
  def private_path
    File.join(CONFIG['root'], 'private')
  end
  
  def show(sheet_file)
    sheet = YAML.load(IO.read(sheet_file)).to_a.first
    sheet[-1] = sheet.last.join("\n") if sheet[-1].is_a?(Array)
    puts sheet.first + ':'
    puts '  ' + sheet.last.gsub("\r",'').gsub("\n", "\n  ").wrap
  end
  
  def rm(sheet_file)
    @git.remove(sheet_file)
    @git.commit_all("-")
  rescue Git::GitExecuteError
    FileUtils.rm_rf(sheet_file)
  end
  
  def add(sheet_file)
    unless File.exist?(sheet_file)
      breaker = sheet_file.rindex(File::Separator)+1
      path = sheet_file[0,breaker]
      title = @sheet.split(File::Separator).join('::')
      FileUtils.mkdir_p(path)
      yml = {"#{title}" => ''}.to_yaml
      open(sheet_file, 'w') {|f| f << yml}
    end
    edit(sheet_file)
  end
  
  def edit(sheet_file)
    sheet = YAML.load(IO.read(sheet_file)).to_a.first
    sheet[-1] = sheet.last.gsub("\r", '')
    body, title = write_to_tempfile(*sheet), sheet.first
    if body.strip.empty?
      rm(sheet_file)
    else
      open(sheet_file,'w') {|f| f << {title => body}.to_yaml}
      @git.add
      @git.commit_all("-")
    end
    true
  end
  
  private
  def editor
    ENV['VISUAL'] || ENV['EDITOR'] || "vim"
  end
  
  def write_to_tempfile(title, body = nil)
    title = title.gsub(/\/|::/, '-')
    # god dammit i hate tempfile, this is so messy but i think it's
    # the only way.
    tempfile = Tempfile.new(title + '.cheat')
    tempfile.write(body) if body
    tempfile.close
    system "#{editor} #{tempfile.path}"
    tempfile.open
    body = tempfile.read
    tempfile.close
    body
  end
  
  def all_sheets
    @git.ls_files.to_a.map {|f| 
      title_of_file(f[0])}
  end
  
  def title_of_file(f)
    f[0..((f.rindex('.')||0) - 1)]
  end
  
end