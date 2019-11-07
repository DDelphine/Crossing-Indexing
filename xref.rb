require_relative "main.rb"

symbols = readdump()
puts "hello"
puts symbols
puts "START HTML HERE"

#Create html header
result = "<!DOCTYPE html> 
    <html>
            <h1>Cross Indexing<h1>
            <h2>CSC 254 Assignment 4</h2>
            <h3>Mingzhe Du & Advaith Suresh</h3>
            <div>"
#add first row of assembly table
assembly_table =  "  <table style=i\"float: left\">
    <tr>
    	<th>Assembly</th>
        <th>Source</th>
    </tr>"

f = false
File.readlines('ASSEMBLY').each do |line|
  tmp = line.strip
  line =line.gsub("<", "&lt").gsub(">", "&gt")
  arr = line.gsub(/\s/m, ' ').strip.split(" ")
  addr = arr[0]
  if !addr.nil? == true && addr.match(/:/)
    addr = addr.gsub(/:/, '')
  symbols.each do |key, value|
    asmly_addr = value.keys
    asmly_addr.each do |item|
      if item.kind_of?(Array)
        if item[0].match(/#{addr}/)
          #puts "#{tmp}                               #{'c:'+value[item]}"
          assembly_table = assembly_table +"<tr><td>#{tmp}</td><td>#{value[item]}</td></tr>"
          f = true
        end
      else
        if item.match(/#{addr}/)
          #puts "#{tmp}                               #{'c:'+value[item]}"
          assembly_table = assembly_table +"<tr><td>#{tmp}</td><td>#{value[item]}</td></tr>"
          f = true
        end
      end
    end
  end
  end
 if f == false
   puts line
   assembly_table = assembly_table +"<tr><td>" + line + "</td></tr>"
 end
 f = false
end
result = result + assembly_table + "</div>
        </body>
    </html>"
puts result
