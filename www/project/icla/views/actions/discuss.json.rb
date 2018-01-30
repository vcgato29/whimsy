require 'socket'
require 'net/http'
require 'pathname'
require 'json'

# find pmc and user information
# all ppmcs are also pmcs but not all pmcs are ppmcs

pmc = ASF::Committee.find(@pmc)
ppmc = ASF::Podling.find(@pmc)
pmc_type = if ppmc and ppmc.status == 'current' then 'PPMC' else 'PMC' end

user = ASF::Person.find(env.user)


begin
  Socket.getaddrinfo(@iclaemail[/@(.*)/, 1].untaint, 'smtp')

  if ASF::Person.find_by_email(@iclaemail)
    _error "ICLA already on file for #{@iclaemail}"
  end
rescue
  _error 'Invalid domain name in email address'
  _focus :iclaemail
end
# create the discussion object
date = Time.now.to_date.to_s
contributor = {:name => @iclaname, :email => @iclaemail}
comment = @proposalText + '\n' + @discussComment
comments = [{:member => @proposer, :timestamp => date, :comment => comment}]
discussion = {
  :phase => 'discuss',
  :proposer => @proposer,
  :subject => @subject,
  :project => @pmc,
  :contributor => contributor,
  :comments => comments
}

  # generate a token
token = pmc.name + '-' + date + '-' + Digest::MD5.hexdigest(@iclaemail)[0..5]

# save the discussion object to a file
discussion_json = discussion.to_json
file_name = '/srv/icla/' + token + '.json'
File.open(file_name.untaint, 'w') {|f|f.write(discussion_json)}

# create the email to the pmc

# add user and pmc emails to the response
_userEmail "#{user.public_name} <#{user.mail.first}>" if user
_pmcEmail "private@#{pmc.mail_list}.apache.org" if pmc

path = Pathname.new(env['REQUEST_URI']) + "../../?token=#{token}"
scheme = env['rack.url_scheme'] || 'https'
link = "#{scheme}://#{env['HTTP_HOST']}#{path}"

# add token and invitation to the response
_token token
_subject params['subject']
_discussion discussion
_message %{
Use this link to continue the discussion:

#{link}
}