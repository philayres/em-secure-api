module SecureApi
  # Adapted from the Rack::Multipart::Parse class of the Rack project
  # https://github.com/rack/rack
  #
  class Multipart
    BUFSIZE = 16384000
    EOL = "\r\n"
    MULTIPART_BOUNDARY = "AaB03x"
    MULTIPART = %r|\Amultipart/.*boundary=\"?([^\";,]+)\"?|n
    TOKEN = /[^\s()<>,;:\\"\/\[\]?=]+/
    CONDISP = /Content-Disposition:\s*#{TOKEN}\s*/i
    DISPPARM = /;\s*(#{TOKEN})=("(?:\\"|[^"])*"|#{TOKEN})/
    RFC2183 = /^#{CONDISP}(#{DISPPARM})+$/i
    BROKEN_QUOTED = /^#{CONDISP}.*;\sfilename="(.*?)"(?:\s*$|\s*;\s*#{TOKEN}=)/i
    BROKEN_UNQUOTED = /^#{CONDISP}.*;\sfilename=(#{TOKEN})/i
    MULTIPART_CONTENT_TYPE = /Content-Type: (.*)#{EOL}/ni
    MULTIPART_CONTENT_DISPOSITION = /Content-Disposition:.*\s+name="?([^\";]*)"?/ni
    MULTIPART_CONTENT_ID = /Content-ID:\s*([^#{EOL}]*)/ni
    
    DUMMY = Struct.new(:parse).new
    
    attr_reader :params
    
    def initialize(content_type, io, content_length)
      @buf            = ""

      if @buf.respond_to? :force_encoding
        @buf.force_encoding Encoding::ASCII_8BIT
      end

      @params         = {}
      content_type =~ MULTIPART
      @boundary       = "--#{$1}"
      @io             = io
      @content_length = content_length
      @boundary_size  = @boundary.bytesize + EOL.size

      if @content_length
        @content_length -= @boundary_size
      end

      @rx = /(?:#{EOL})?#{Regexp.quote(@boundary)}(#{EOL}|--)/n
      @full_boundary = @boundary + EOL
                
    end

    def parse
      fast_forward_to_first_boundary

      loop do
        head, filename, content_type, name, body =
          get_current_head_and_filename_and_content_type_and_name_and_body

        # Save the rest.
        if i = @buf.index(rx)
          body << @buf.slice!(0, i)
          @buf.slice!(0, @boundary_size+2)

          @content_length = -1  if $1 == "--"
        end

        get_data(filename, body, content_type, name, head) do |data|
          tag_multipart_encoding(filename, content_type, name, data)

          normalize_params(@params, name, data)
        end

        # break if we're at the end of a buffer, but not if it is the end of a field
        break if (@buf.empty? && $1 != EOL) || @content_length == -1
      end

      @io.rewind

      
      @params
    end

    private
    def full_boundary; @full_boundary; end

    def rx; @rx; end
    
    # Cutdown function from Rack::Utils. Did not need the handling of 'array' parameters
    def normalize_params(params, name, v = nil)
      name =~ %r(\A[\[\]]*([^\[\]]+)\]*)
      k = $1 || ''
      after = $' || ''

      return if k.empty?

      if after == ""
        params[k.to_sym] = v
      end

      return params
    end

    def fast_forward_to_first_boundary
      loop do
        content = @io.read(BUFSIZE)                        
        raise EOFError, "bad content body" unless content
        @buf << content

        while @buf.gsub!(/\A([^\n]*\n)/, '')
          read_buffer = $1          
          return if read_buffer == full_boundary
        end

        raise EOFError, "bad content body" if @buf.bytesize >= BUFSIZE
      end
    end

    def get_current_head_and_filename_and_content_type_and_name_and_body
      head = nil
      body = ''

      if body.respond_to? :force_encoding
        body.force_encoding Encoding::ASCII_8BIT
      end

      filename = content_type = name = nil

      until head && @buf =~ rx
        if !head && i = @buf.index(EOL+EOL)
          head = @buf.slice!(0, i+2) # First \r\n

          @buf.slice!(0, 2)          # Second \r\n

          content_type = head[MULTIPART_CONTENT_TYPE, 1]
          name = head[MULTIPART_CONTENT_DISPOSITION, 1] || head[MULTIPART_CONTENT_ID, 1]

          filename = get_filename(head)

          if filename
            body = Tempfile.new("SecureApiMultipart")
            body.binmode  if body.respond_to?(:binmode)
          end

          next
        end

        # Save the read body part.
        if head && (@boundary_size+4 < @buf.size)
          body << @buf.slice!(0, @buf.size - (@boundary_size+4))
        end

        raise "@content_length < -1 #{@content_length}" if @content_length < -1
        content = @io.read(@content_length && BUFSIZE >= @content_length ? @content_length : BUFSIZE)
        raise EOFError, "bad content body"  if content.nil? || content.empty?

        @buf << content
        @content_length -= content.size if @content_length
      end

      [head, filename, content_type, name, body]
    end

    def get_filename(head)
      filename = nil
      case head
      when RFC2183
        filename = Hash[head.scan(DISPPARM)]['filename']
        filename = $1 if filename and filename =~ /^"(.*)"$/
      when BROKEN_QUOTED, BROKEN_UNQUOTED
        filename = $1
      end

      return unless filename

      if filename.scan(/%.?.?/).all? { |s| s =~ /%[0-9a-fA-F]{2}/ }
        filename = CGI.unescape(filename)
      end

      scrub_filename filename

      if filename !~ /\\[^\\"]/
        filename = filename.gsub(/\\(.)/, '\1')
      end
      filename
    end

    if "<3".respond_to? :valid_encoding?
      def scrub_filename(filename)
        unless filename.valid_encoding?
          # FIXME: this force_encoding is for Ruby 2.0 and 1.9 support.
          # We can remove it after they are dropped
          filename.force_encoding(Encoding::ASCII_8BIT)
          filename.encode!(:invalid => :replace, :undef => :replace)
        end
      end

      CHARSET    = "charset"
      TEXT_PLAIN = "text/plain"

      def tag_multipart_encoding(filename, content_type, name, body)
        name.force_encoding Encoding::UTF_8

        return if filename

        encoding = Encoding::UTF_8

        if content_type
          list         = content_type.split(';')
          type_subtype = list.first
          type_subtype.strip!
          if TEXT_PLAIN == type_subtype
            rest         = list.drop 1
            rest.each do |param|
              k,v = param.split('=', 2)
              k.strip!
              v.strip!
              encoding = Encoding.find v if k == CHARSET
            end
          end
        end

        name.force_encoding encoding
        body.force_encoding encoding
      end
    else
      def scrub_filename(filename)
      end
      def tag_multipart_encoding(filename, content_type, name, body)
      end
    end

    def get_data(filename, body, content_type, name, head)
      data = body
      if filename == ""
        # filename is blank which means no file has been selected
        return
      elsif filename
        body.rewind

        # Take the basename of the upload's original filename.
        # This handles the full Windows paths given by Internet Explorer
        # (and perhaps other broken user agents) without affecting
        # those which give the lone filename.
        filename = filename.split(/[\/\\]/).last

        data = {:filename => filename, :type => content_type,
                :name => name, :tempfile => body, :head => head}
      elsif !filename && content_type && body.is_a?(IO)
        body.rewind

        # Generic multipart cases, not coming from a form
        data = {:type => content_type,
                :name => name, :tempfile => body, :head => head}
      end

      yield data
    end
  end
end
