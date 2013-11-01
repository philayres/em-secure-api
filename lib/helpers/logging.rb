class Logger
  
  def initialize logname
    @hostname = (`hostname`).chomp  
    @logname = logname
    @logdir = BaseDirs[:log]
    
    raise "No log directory specified in configuration directories" unless @logdir && !@logdir.empty?
  end
  
  def self.start_logging logname='log'
    @logger ||= Logger.new logname
  end
  
  def log_filename    
    "#{@logdir}/#{@logname}_#{Time.now.strftime('%Y%m%d')}.log"
  end
  
  def log_entry sev, text, request
    "#{DateTime.now.to_s} [#{@hostname}] [#{request}] [#{sev.to_s.upcase}] #{text}"
  end
  
  def write_log(sev, text, request)
        
    t = log_entry(sev, text, request)    
    File.open(log_filename, 'w+').syswrite(t)
    puts t if DEBUG
  end
  
  def log(text, request='general')
    write_log(:log, text, request)  
  end
  
  def info(text, request='general')
    write_log(:info, text, request)  
  end
  
  def warn(text, request='general')
    write_log(:warn, text, request)  
  end
  
  def error(text, request='general')
    write_log(:error, text, request)
  end
  
  def critical(text, request='general')
    write_log(:critical, text, request)
  end
    
end