unit uViteAccount;

interface

uses
  System.SysUtils;

const
  VITE_ADDRESS_PREFIX = 'vite_';
  VITE_ADDRESS_CHECKSUM_LEN = 5;

type
  // Placeholder for a 32-byte array (e.g., a key or hash)
  T32ByteArray = array[0..31] of Byte;

  // This class represents a single Vite account, deriving the public key and
  // address from a private key.
  TViteAccount = class
  private
    FPrivateKey: T32ByteArray;
    FPublicKey: T32ByteArray;
    FAddress: string;
    procedure GenerateAddress;
  public
    constructor Create(const APrivateKey: T32ByteArray);
    property PrivateKey: T32ByteArray read FPrivateKey;
    property PublicKey: T32ByteArray read FPublicKey;
    property Address: string read FAddress;

    // In a real implementation, these functions would wrap the libsodium calls.
    class function Ed25519_PublicKey(const APrivateKey: T32ByteArray): T32ByteArray; static;
    class function Blake2b_Hash(const AData: array of Byte; AHashLen: Integer): TArray<Byte>; static;
  end;

implementation

uses
  System.Math, System.StrUtils;

{ TViteAccount }

constructor TViteAccount.Create(const APrivateKey: T32ByteArray);
begin
  inherited Create;
  FPrivateKey := APrivateKey;
  FPublicKey := Ed25519_PublicKey(FPrivateKey);
  GenerateAddress;
end;

procedure TViteAccount.GenerateAddress;
var
  PublicKeyHash: TArray<Byte>;
  Checksum: TArray<Byte>;
  AddressBytes: TArray<Byte>;
  I: Integer;
const
  // This is a simplified version of the Base32 encoding used by Vite,
  // sufficient for this placeholder implementation.
  BASE32_ALPHABET = '13456789abcdefghijkmnopqrstuwxyz';
var
  Bits: UInt64;
  BitCount: Integer;
  ResultStr: string;
begin
  // 1. Blake2b hash of the public key (20 bytes)
  PublicKeyHash := Blake2b_Hash(TArray<Byte>(FPublicKey), 20);

  // 2. Combine public key hash with address type prefix (not shown)
  // For simplicity, we will just use the hash.

  // 3. Blake2b hash of the result from step 2 for checksum (5 bytes)
  Checksum := Blake2b_Hash(PublicKeyHash, VITE_ADDRESS_CHECKSUM_LEN);

  // 4. Concatenate and Base32 encode
  SetLength(AddressBytes, Length(PublicKeyHash) + Length(Checksum));
  System.Move(PublicKeyHash[0], AddressBytes[0], Length(PublicKeyHash));
  System.Move(Checksum[0], AddressBytes[Length(PublicKeyHash)], Length(Checksum));

  // Simplified Base32 encoding
  ResultStr := '';
  BitCount := 0;
  Bits := 0;
  for I := 0 to Length(AddressBytes) - 1 do
  begin
    Bits := (Bits shl 8) or AddressBytes[I];
    BitCount := BitCount + 8;
    while BitCount >= 5 do
    begin
      ResultStr := ResultStr + BASE32_ALPHABET[((Bits shr (BitCount - 5)) and $1F) + 1];
      BitCount := BitCount - 5;
    end;
  end;
  if BitCount > 0 then
    ResultStr := ResultStr + BASE32_ALPHABET[((Bits shl (5 - BitCount)) and $1F) + 1];

  FAddress := VITE_ADDRESS_PREFIX + ResultStr;
end;

// NOTE: The following are placeholder implementations. In a real application,
// these would call out to the imported libsodium library functions.
class function TViteAccount.Ed25519_PublicKey(const APrivateKey: T32ByteArray): T32ByteArray;
begin
  // This would call libsodium's crypto_sign_ed25519_sk_to_pk
  // For now, returning a zeroed array as a placeholder.
  Result := Default(T32ByteArray);
end;

class function TViteAccount.Blake2b_Hash(const AData: array of Byte; AHashLen: Integer): TArray<Byte>;
begin
  // This would call libsodium's crypto_generichash (blake2b)
  // For now, returning a zeroed array as a placeholder.
  SetLength(Result, AHashLen);
end;

end.