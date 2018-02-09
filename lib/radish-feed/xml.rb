require 'rexml/document'
require 'radish-feed/renderer'

module RadishFeed
  class XML < Renderer
    def generate (result)
      xml = REXML::Document.new
      xml.add(REXML::XMLDecl.new('1.0', 'UTF-8'))
      xml.add_element(REXML::Element.new('result'))
      status = xml.root.add_element('status')
      status.add_text(result[:response][:status].to_s)
      message = xml.root.add_element('message')
      message.add_text(result[:response][:message] || 'error')
      return xml
    end
  end
end
