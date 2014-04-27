include Origami

class SignPDF
  
  attr_accessor :in_filename, :out_filename
  
  def initialize user_identity, password
    
    @key = user_identity.get_private_key(password)
    @cert = user_identity.get_certificate chain: true, x509: true
    @user_identity = user_identity    
  end
  
  
  
  def sign options
    
    @pdf = Origami::PDF.read(@in_filename)        
    page = @pdf.get_page(options[:page])
    
    reason = options[:reason] || 'Signed'
    caption = options[:caption] || "\n#{reason}\n#{@user_identity.name_first} #{@user_identity.name_last}\n#{@user_identity.email}\n#{DateTime.now.to_s}"
    location = "#{@user_identity.city}, #{@user_identity.state}, #{@user_identity.country}"
    
    
    llx = options[:x_pos] || 89.0
    lly = options[:y_pos] || 386.0
    width = 210.0
    height = 63.0
    urx = llx + width
    ury = lly - height
    
    text = Annotation::FreeText.new
    text.Rect = Origami::Rectangle[:llx => llx, :lly => lly, :urx => urx, :ury => ury]
    text.Contents = caption        
    text.Border = [ 2 , 2, 2 ]        
    page.add_annot(text)
    
    sigannot = Annotation::Widget::Signature.new
    sigannot.Rect = Rectangle[:llx => llx-1, :lly => lly+1, :urx => urx+1, :ury => ury-1]
    sigannot.Border = [ 0,0,0 ]    
    page.add_annot(sigannot)

    @pdf.sign(@cert, @key, 
      :method => 'adbe.pkcs7.sha1',
      :annotation => sigannot, 
      :location => location, 
      :contact => @user_identity.email, 
      :reason => reason
    )
    
    @pdf.save(@out_filename)

    #cert = user_identity.get_certificate chain: true
    #File.write "./testfiles/phil.cer", cert    
    #rootcert = @user_identity.get_root_certificate 
    #File.write "./testfiles/repse.cer", rootcert    
    
  end
  

  
  
end
