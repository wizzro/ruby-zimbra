module Zimbra
  class Version
		class << self
      def get
        VersionService.get_version
			end
		end

		attr_accessor :version, :release, :buildDate, :buildHost

		def initialize(options = {})
			self.version = options[:version]
			self.release = options[:release]
			self.buildDate = options[:buildDate]
			self.buildHost = options[:buildHost]
    end
	end

  class VersionService < HandsoapService
    def get_version
      xml = invoke("n2:GetVersionInfoRequest")
      Parser.version_response(xml/"//n2:info")
    end

    class Parser
      class << self
        def version_response(node)
          version = (node/'@version').to_s
          release = (node/'@release').to_s
          buildDate = (node/'@buildDate').to_s
          buildHost = (node/'@buildHost').to_s
          Zimbra::Version.new(:version => version, :release => release, :buildDate => buildDate, :buildHost => buildHost)
				end
			end
		end
	end
end
