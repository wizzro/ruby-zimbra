module Zimbra
  class License
		class << self
      def get
        LicenseService.get_license
			end
		end

		attr_accessor :expiration

		def initialize(options = {})
			self.expiration = options[:expiration]
    end
	end

  class LicenseService < HandsoapService
    def get_license
      xml = invoke("n2:GetLicenseInfoRequest")
      Parser.license_response(xml/"//n2:expiration")
    end

    class Parser
      class << self
        def license_response(node)
          expiration	= (node/'@date').to_s
          Zimbra::License.new(:expiration => expiration)
				end
			end
		end
	end
end
