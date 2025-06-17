# change-dir - changes the current directory. returns that we tried to change directories
function func_cd 
{
    param([string] $directory) # the directory we are going to change to

    cd $directory
    return "Attempted to change to $directory."
}