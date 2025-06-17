# rm-time - removes the specific item or directory and returns that we tried to remove the item
function func_rm 
{
    param([string] $item) # the item we want to remove

    rm $item

    return "Attempted to remove $item."

}