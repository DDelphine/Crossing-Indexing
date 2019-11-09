require_relative "main.rb"


dwarf_dump= `llvm-dwarfdump --debug-line #{ARGV[0]}` #retrieves dwarfdump of the program passed in argument
assembly = `objdump --disassemble #{ARGV[0]}` #retrievess objdump
lookup_table_master = readdwarf(dwarf_dump) #calls function from readdump.rb that returns a hashmap containing assembly lines mapped to corresponding source lines, as well as a list of lines not used
lookup_table = lookup_table_master[0]
unused_table = lookup_table_master[1]

#replace all <> with &lt and &gt before adding any html code
assembly.each_line do |line|
  line =line.gsub("<", "&lt").gsub(">", "&gt")
end


#tag assembly lines with fixed-address control transfer
assembly_with_sourcecode= [] #list of sourcecode lines that have corresponding assembly code
lookup_table.each do |key, value| #iterate through each key map in table, key = source code file
  asmly_addr = value.keys #array of assembly addresses with corresponding source code
  asmly_addr.each do |item|
    if item.kind_of?(Array) #sometimes multiple assembly code map to one source code
      item.each do |item2|
        item2= item2[12..18] #gets the abbreviated address
        assembly_with_sourcecode << item2
      end
    else
        item = item[12..18]
        assembly_with_sourcecode << item
     end
  end
end

destinations= [] #list of destination addresses that we must link to
assembly_two= "" #new assembly dump, modified to have source anchor points
#place link anchor at starting line
assembly.each_line do |line| 
  templine= line.strip
 # puts templine[0..5] #gets the abbreviated assembly address
  if assembly_with_sourcecode.include?templine[0..5]
  #  puts line +"  copy"
    matched = line[/[^#][ +]\h{6,6}[^:]/] #matches addresses without a colon after it (so it only matches address calls)
    if matched.eql? nil
      matched = ""
    else
      destinations << matched.strip #add to list of destinations
    end
  #  puts  matched
    line= line.sub(/[^#][ +]\h{6,6}[^:]/,"<a href=\"#"+matched.strip+"\">"+matched.strip+"</a>") #replace the address call with an anchor point
   # puts "subbed: "+ line
  end
  assembly_two = assembly_two + line #adds modified line to assembly_two
end
assembly = assembly_two

#place link anchor at destination line, same process as above
assembly_three = ""
assembly_two.each_line do |line|
  templine= line.strip
 # puts templine[0..5]
  if destinations.include?templine[0..5]
  #  puts line +"  copy"
    matched = line[/[^#][ +]\h{6,6}/]
    if matched.eql? nil
      matched = ""
    else
      destinations << matched.strip #add to list of destinations
    end
   # puts  matched
    line= line.sub(/[^#][ +]\h{6,6}/,"<a id=\""+matched.strip+"\">"+matched.strip+"</a>")
   # puts "subbed: "+ line
  end
  assembly_three = assembly_three + line
end
assembly = assembly_three
#END OF CREATING LOCATION-SPECIFIC LINKS


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
#Start going through the assembly code line-by-line to add them to the table
assembly.each_line do |line|
  linenum = linenum + 1 #tracks the line number of the assembly code
  linenum_string = linenum.to_s
  linenum_string= linenum_string + ". "
  tmp = line.strip
  #line =line.gsub("<", "&lt").gsub(">", "&gt")
  arr = line.gsub(/\s/m, ' ').strip.split(" ")
  addr = arr[0]
  if !addr.nil? == true && addr.match(/:/)
    addr = addr.gsub(/:/, '')
  lookup_table.each do |key, value| #iterates through lookup table
    asmly_addr = value.keys
    asmly_addr.each do |item|
      current_source_line = value[item][0].to_i #current source line being checked
      if item.kind_of?(Array) #the source line appears for more than 1 assembly line
        if item[0].match(/#{addr}/)
          if item[0].match(/&ltmain&gt/) #creates a link at main
            assembly_table += "<tr><td><a id=\"target\"></a>"
          else
            assembly_table += "<tr><td>"
          end
          #puts "#{tmp}                               #{'c:'+value[item]}"
          if key.eql? previous_key #checks if the file the source code comes from has changed
          else
           assembly_table += "<tr><td>~</td><td>#{key}</td></tr><tr><td>" #if it has changed, display new source code file name
          end
          previous_key = key
          assembly_table = assembly_table +"#{linenum_string}#{tmp}</td><td>#{value[item]}</td></tr>" #add new row to table with "assembly => source"
          f = true
          #check if next source code lines do not have corresponding assembly lines
          more_lines = true #remains true as long as the next source line does not have corresponding assembly lines
          while more_lines 
            current_source_line= current_source_line +1
            if unused_table.key?(key) #checks the current file in the table containing unused source lines
              source_lines= unused_table[key]
              if source_lines.key?(current_source_line) #checks if the next source line is unused
                assembly_table += "<tr><td>~</td><td>#{current_source_line}. #{source_lines[current_source_line]}</td></tr><tr><td>"#create new table row to display unused source code
              else
                 more_lines = false #if next line is used, then stop searching
              end
            end
          end #end of while loop
        end
      else #this code is similar to the code above, this if statement axists to check if there are multiple assembly lines that map to one source line
        if item.match(/#{addr}/)
          if item.match(/&ltmain&gt/)
            assembly_table += "<tr><td><a id=\"target\"></a>"
          else
            assembly_table += "<tr><td>"
          end
          #puts "#{tmp}                               #{'c:'+value[item]}"
          if key.eql? previous_key
          else
            assembly_table += "<tr><td>~</td><td>#{key}</td></tr><tr><td>"
          end
          previous_key = key
          assembly_table = assembly_table +"#{linenum_string}#{tmp}</td><td>#{value[item]}</td></tr>"
          f = true
          #check if next source code lines do not have corresponding assembly lines
          more_lines = true #remains true as long as the next source line does not have corresponding assembly lines
          while more_lines
            current_source_line = current_source_line + 1
            if unused_table.key?(key) 
              source_lines= unused_table[key]
              if source_lines.key?(current_source_line)
                 assembly_table += "<tr><td>~</td><td>#{current_source_line}. #{source_lines[current_source_line]}</td></tr><tr><td>"#create new table row to display unused source code
              else
                 more_lines = false
              end
            end
          end #end of while loop
        end
      end #end of if/else
    end #end of item loop
  end #end of |key,value| loop
  end
 if f == false  #this means that there is no source code corresponding to the assembly line, so just print the assembly line
   if line.match(/&ltmain&gt/)
            assembly_table += "<tr><td><a id=\"target\"></a>"
   else
      assembly_table += "<tr><td>"
   end
   assembly_table = assembly_table  +linenum_string+ line + "</td></tr>"
 end
 f = false
end
result = result + assembly_table + "<a href=\"#target\">Link to main method</a>
</div>
        </body>
    </html>"
puts "HTML code has been successfully generated in html directory: ./html/output.html"


#Create directory and write html files
Dir.mkdir('html') unless Dir.exist?('html') #creates directory if it does not already exist
File.open('html/output.html','w') do |file|
  file.write(result) 
end
