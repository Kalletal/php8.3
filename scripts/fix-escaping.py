with open('generate-wizard.py', 'r') as f:
    content = f.read()

# Fix the escape sequences - need 4 backslashes to get \' in output
content = content.replace('fr_name_escaped = fr_name.replace("\'", "\'")', 
                         r'fr_name_escaped = fr_name.replace("'"'"'", r"\'"'"'")')

content = content.replace('fr_cat_name_escaped = fr_cat_name.replace("\'", "\'")', 
                         r'fr_cat_name_escaped = fr_cat_name.replace("'"'"'", r"\'"'"'")')

content = content.replace('fr_desc_escaped = fr_desc.replace("\'", "\'")', 
                         r'fr_desc_escaped = fr_desc.replace("'"'"'", r"\'"'"'")')

# Find and fix the missing append line for extensions
import re
pattern = r'(fr_desc_escaped = fr_desc\.replace.*?\n)\s+i18n_parts\.append\(f\'      \/\/ )'
replacement = r'\1            i18n_parts.append(f\'      {ext_id}: \\'{fr_desc_escaped}\\',\')\n        i18n_parts.append(f\'      // '
content = re.sub(pattern, replacement, content)

with open('generate-wizard.py', 'w') as f:
    f.write(content)

print('✓ Fixed Python escape sequences')
