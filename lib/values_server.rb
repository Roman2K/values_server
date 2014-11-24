module ValuesServer
  autoload :Server,     'values_server/server'
  autoload :Cache,      'values_server/cache'
  autoload :ThreadPool, 'values_server/thread_pool'

  def self.format_exc(err)
    ["#{err.class}: #{err}", *err.backtrace] * "\n"
  end
end
