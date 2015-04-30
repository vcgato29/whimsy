#
# Add action item status updates to pending list
#

pending = Pending.get(env.user, @agenda)
pending['status'] ||= []

# identify the action to be updated
update = {
  owner: @owner,
  text: @text,
  pmc: @pmc,
  date: @date
}

# search for a match against previously pending status updates
match = nil
pending['status'].each do |status|
  found = true
  update.each do |key, value|
    found=false if value != status[value]
  end
  match = status if found
end

# if none found, add update to the list
pending['status'] << update if not match

# change the status in the update
update[:status] =
  @status.strip.gsub(/\s+/, ' ').gsub(/(.{1,62})(\s+|\Z)/, "\\1\n").chomp

Pending.put(env.user, pending)

pending
