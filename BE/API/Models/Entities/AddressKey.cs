using API.Models.BaseModel;
using Dapper;

namespace API.Models.Entities;

public class AddressKey : EntityKey
{
    public int AddressID { get; set; }
    public AddressKey(int addressID)
    {
        AddressID = addressID;
    }

    public override void AttachKeys(ref DynamicParameters parameters)
    {
        // Redefine how to attach keys
        base.AttachKeys(ref parameters);
    }
}
