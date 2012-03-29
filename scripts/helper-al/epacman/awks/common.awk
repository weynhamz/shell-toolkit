#
# File name: functions.awk
#

#Function
#Get Array Size.
function size(array) {
    count = 0;
    for(item in array) {
        count++;
    }
    return count;
}

#Function
#Compare two strings alphabetically
#if a is before b return 1, else return 0.
function comp(a,b) {
    if(a=="" || b=="") return 3;
    if(substr(a,1,1) > substr(b,1,1)) {
        return 1;
    } else if(substr(a,1,1) < substr(b,1,1)) {
        return 0;
    } else if(substr(a,1,1) == substr(b,1,1)) {
        if (length(a) == 1) {
            return 0;
        } else if (length(b) == 1) {
            return 1;
        } else {
            return comp(substr(a,2),substr(b,2));
        }
    }
}

function ksort(array,n)
{
    max = "";
    if(n == "")
        n=size(array);
    for(item in array) {
        result = comp(item,max);
        if(array[item] <= n && result) {
            max = item;
        } else if(array[item] == n){
            print item;
        }
    }
    array[max] = n;
    if(n ==0) {
        for (l=1;l<=size(array);l++) {
            for(item in array) {
                if(l == array[item]) {
                    array[l]=item;
                    delete array[""];
                    delete array[item];
                }
            }
        }
    } else {
        ksort(array,n-1);
    }
}

function var_dump(array){
    printf("VAR_DUMP:\n");
    for(item in array){
        printf("\033[40m%s:%s\033[0m\n",item,array[item]);
    }
    printf("\n");
}
