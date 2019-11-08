require_relative "main.rb"


dwarf_dump= `llvm-dwarfdump --debug-line #{ARGV[0]}`
assembly = `objdump --disassemble #{ARGV[0]}` 
lookup_table = readdwarf(dwarf_dump)
puts "Lookup Table"
puts lookup_table

#Create html header
result = "<!DOCTYPE html> 
    <html>
            <h1>Cross Indexing<h1>
            <h2>CSC 254 Assignment 4</h2>
            <h3>Mingzhe Du & Advaith Suresh</h3>
            <style>
            table {
            border-collapse: collapse;
            width: 100%;
            }
            th, td {
            text-align: left;
            padding: 8px;
            }
            tr:nth-child(odd) {background-color: #f2f2f2;}
</style>
            <div>"
#add first row of assembly table
assembly_table =  "  <table style=i\"float: left\">
    <tr>
    	<th>Assembly</th>
        <th>Source</th>
    </tr>"

f = false
linenum =0
previous_key= "" #tracks the previous key (file that source line is in) 
assembly.each_line do |line|
  linenum = linenum + 1 
  linenum_string = linenum.to_s
  linenum_string= linenum_string + ". "
  tmp = line.strip
  line =line.gsub("<", "&lt").gsub(">", "&gt")
  arr = line.gsub(/\s/m, ' ').strip.split(" ")
  addr = arr[0]
  if !addr.nil? == true && addr.match(/:/)
    addr = addr.gsub(/:/, '')
  lookup_table.each do |key, value|
    #if key.e previous_key
    #else
      #assembly_table += "<tr><td>~</td><td>#{key}</td></tr>"
    #end
   # previous_key = key
    asmly_addr = value.keys
    asmly_addr.each do |item|
      if item.kind_of?(Array)
        if item[0].match(/#{addr}/)
          #puts "#{tmp}                               #{'c:'+value[item]}"
          if key.eql? previous_key
          else
           assembly_table += "<tr><td>~</td><td>#{key}</td></tr>"
          end
          previous_key = key
          assembly_table = assembly_table +"<tr><td>#{linenum_string}#{tmp}</td><td>#{value[item]}</td></tr>"
          f = true
        end
      else
        if item.match(/#{addr}/)
          #puts "#{tmp}                               #{'c:'+value[item]}"
          if key.eql? previous_key
          else
            assembly_table += "<tr><td>~</td><td>#{key}</td></tr>"
          end
          previous_key = key
          assembly_table = assembly_table +"<tr><td>#{linenum_string}#{tmp}</td><td>#{value[item]}</td></tr>"
          f = true
        end
      end #end of if/else
    end #end of item loop
  end #end of |key,value| loop
  end
 if f == false
   puts line
   assembly_table = assembly_table +"<tr><td>" +linenum_string+ line + "</td></tr>"
 end
 f = false
end
result = result + assembly_table + "</div>
        </body>
    </html>"
puts "HTML CODE GENERATED:"
puts result
