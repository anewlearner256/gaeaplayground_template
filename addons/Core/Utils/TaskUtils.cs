
using System.Threading.Tasks;

namespace Gaea.Utils
{
    public static class TaskUtils
    {
        public static Task CompletedTask => Task.Delay(0);
    }
}