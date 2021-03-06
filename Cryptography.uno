using Uno;
using Uno.Collections;
using Uno.IO;
using Uno.Text;
using Fuse;
namespace Cryptography
{
    /*CODE ORIGINALLY
    FROM CODEPROJECT ARTICLE : http://www.codeproject.com/Articles/592275/OTP-One-Time-Password-Demystified
    UNDER LICENSE: http://www.codeproject.com/info/cpol10.aspx

    PORTED TO UNO WITH BASIC REFACTORING: Sean McKay, 2015
    */
    struct SHA_TRANSF
    {
        public  long A;
        public  long B;
        public  long C;
        public  long D;
        public  long E;

        public  long T;
        public  long[] W;
        public  int idxW;

        public new string ToString()
        {
            return "::" + A + "::" + B + "::" + C + "::" + D + "::" + E + "::" + T + "::" + idxW;
        }

    }

    public class mem
    {
        public static void _set(ref byte[] data, int first, byte val, int count)
        {
            for (int nI = 0; nI < count; nI++)
            {
                data[nI + first] = val;
            }
        }

        public static void _cpy(ref byte[] dest, int dest_first, byte[] srce, int srce_first, int count)
        {
            for (int nI = 0; nI < count; nI++)
            {
                dest[dest_first + nI] = srce[nI + srce_first];
            }
        }
    }

   /// <summary>
    /// This class implements the SHA1 hash algorithm
    /// </summary>
    public class Sha1
    {

        //#region SHA f()-functions

        static long andOrNot(long x, long y, long z)
        {
            return ((x & y) | (~x & z));
        }

        static long xorEm(long x, long y, long z)
        {
            //debug_log("XorEM: " + x + " xor " + y + " xor " + z + " = " + (x^y^z));
            return (x ^ y ^ z);
        }

        static long andOr(long x, long y, long z)
        {
            return ((x & y) | (x & z) | (y & z));
        }

        static long xorEm2(long x, long y, long z)
        {
            return (x ^ y ^ z);
        }

        static long f(long n, long x, long y, long z)
        {
            switch (n)
            {
                case 1:
                {
                    return andOrNot(x, y, z);
                }

                case 2:
                {
                    return xorEm(x, y, z);
                }

                case 3:
                {
                    return andOr(x, y, z);
                }

                case 4:
                {
                    return xorEm2(x, y, z);
                }

                default:
                throw new Exception("Wrong parameter");
            }
        }

        //#endregion


        static long Mask32Bit(long x)
        {
            string ls = x.ToString();
            ulong ul;
            if (!ulong.TryParse(ls,out ul))
            {
                debug_log("Mask32Bit Invalid long-->ulong: '" + ls + "'");
                return 0;
            }
            return Mask32Bit(ul);
        }

        static long Mask32Bit(ulong x)
        {
            unchecked
            {
                return (long)(x & maskInt); //0xFFFFFFFF);
            }
        }

        static long RotateLeft32Bit(long x, int n)
        {
            return Mask32Bit(SHA512.rotateleft(ulong.Parse(x.ToString()),n));
            //return Mask32Bit(((x << n) | (long)SHA512.shr((ulong)x,32-n))); 
            //return Mask32Bit(((x << n) | (x >> (32 - n))));
        }

        static long MaskedRotateLeft32Bit(long x, int n)
        {
            return long.Parse(SHA512.maskedrotateleft(ulong.Parse(x.ToString()),n,32).ToString());
            //return Mask32Bit(((x << n) | (long)SHA512.shr((ulong)x,32-n))); 
            //return Mask32Bit(((x << n) | (x >> (32 - n))));
        }

        //#region Unraveled Rotation functions

        static void ModifyTB(int n, ref SHA_TRANSF t)
        {
            long mrl =MaskedRotateLeft32Bit(t.A, 5);
            long fnbcd = f(n, t.B, t.C, t.D);
            t.T =  Mask32Bit(mrl + fnbcd + t.E + t.W[t.idxW++] + CONST[n - 1]);
            //debug_log("TA:" + t.A + "::MRL:" +mrl + "::FNBCD:" + fnbcd);
            t.B = MaskedRotateLeft32Bit(t.B, 30);
        }

        static void ModifyEA(int n, ref SHA_TRANSF t)
        {
            t.E = Mask32Bit(MaskedRotateLeft32Bit(t.T, 5) + f(n, t.A, t.B, t.C) + t.D + t.W[t.idxW++] + CONST[n - 1]);
            //long ta = t.A;
            t.A = MaskedRotateLeft32Bit(t.A, 30);
            //debug_log("TA: " + ta + " =RL30=> " + t.A);
        }

        static void ModifyDT(int n, ref SHA_TRANSF t)
        {
            t.D = Mask32Bit(MaskedRotateLeft32Bit(t.E, 5) + f(n, t.T, t.A, t.B) + t.C + t.W[t.idxW++] + CONST[n - 1]);
            t.T = MaskedRotateLeft32Bit(t.T, 30);
        }

        static void ModifyCE(int n, ref SHA_TRANSF t)
        {
            t.C = Mask32Bit(MaskedRotateLeft32Bit(t.D, 5) + f(n, t.E, t.T, t.A) + t.B + t.W[t.idxW++] + CONST[n - 1]);
            //long te = t.E;
            t.E = MaskedRotateLeft32Bit(t.E, 30);
            //debug_log("TE: " + te + " =RL30=> " + t.E);
        }

        static void ModifyBD(int n, ref SHA_TRANSF t)
        {
            long mrl = MaskedRotateLeft32Bit(t.C, 5);
            long fndet = f(n, t.D, t.E, t.T);
            long sum = mrl + fndet + t.A + t.W[t.idxW++] + long.Parse(CONST[n - 1].ToString());
            t.B = Mask32Bit(sum);
            //long tB = t.B;
            t.D = MaskedRotateLeft32Bit(t.D, 30);
            // debug_log("TC:" + t.C + "::MRL:" +mrl + "::FNDET:" + fndet+"::tW[t.idxW]:" + t.W[t.idxW-1] + "::CONST:"+CONST[n-1]+"::SUM:" + sum + "::TB:" + t.B);

        }

        static void ModifyAT(int n, ref SHA_TRANSF t)
        {
            t.A = Mask32Bit(MaskedRotateLeft32Bit(t.B, 5) + f(n, t.C, t.D, t.E) + t.T + t.W[t.idxW++] + CONST[n - 1]);
            t.C = MaskedRotateLeft32Bit(t.C, 30);
        }

        //#endregion



        private void sha_transform()
        {
            int
            i,
            idx = 0;

            SHA_TRANSF tf = new SHA_TRANSF();
            tf.W = new long[80];

            /* SHA_BYTE_ORDER == 1234 */
            for (i = 0; i < 16; ++i)
            {
                tf.T = ((long)data[idx++]) & maskFirstByte; // 0x000000ff;
                tf.T += (((long)data[idx++]) << 8) & maskSecondByte; // 0x0000ff00;
                tf.T += (((long)data[idx++]) << 16) & maskThirdByte; // 0x00ff0000;
                tf.T += (((long)data[idx++]) << 24) & maskFourthByte; // 0xff000000;
                //debug_log("Round: " + i +  "   TFT: " + tf.T);

                //tf.W[i] = ((tf.T << 24) & 0xff000000) | ((tf.T << 8) & 0x00ff0000) |
                //((tf.T >> 8) & 0x0000ff00) | ((tf.T >> 24) & 0x000000ff);
                ulong tfT = ulong.Parse(tf.T.ToString());
                tf.W[i] = ((tf.T << 24) & maskFourthByte) | // & 0xff000000) | 
                    ((tf.T << 8) & maskThirdByte) | // & 0x00ff0000) |
                    (((long)SHA512.shr(tfT ,8)) & maskSecondByte) | // 0x0000ff00) | 
                    (((long)SHA512.shr(tfT ,24)) & maskFirstByte); // & 0x000000ff);
                }

            //HmacSha1.debugBytes(tf.W, "Initial W:");
            for (i = 16; i < 80; ++i)
            {
                tf.W[i] = tf.W[i - 3] ^ tf.W[i - 8] ^ tf.W[i - 14] ^ tf.W[i - 16];
                tf.W[i] = MaskedRotateLeft32Bit(tf.W[i], 1);
            }
            //HmacSha1.debugBytes(tf.W, "Updated W:");

            tf.A = digest[0];
            tf.B = digest[1];
            tf.C = digest[2];
            tf.D = digest[3];
            tf.E = digest[4];
            tf.idxW = 0;

            // UNRAVEL
            //debug_log "::BEFORE::MODIFYTB::" + tf.ToString();
            ModifyTB(1, ref tf);
            //debug_log "::AFTER::MODIFYTB::" + tf.ToString();
            ModifyEA(1, ref tf);
            //debug_log "::AFTER::MODIFYEA::" + tf.ToString();
            ModifyDT(1, ref tf);
            //debug_log "::AFTER::MODIFYDT::" + tf.ToString();
            ModifyCE(1, ref tf);
            //debug_log "::AFTER::MODIFYCE::" + tf.ToString();
            ModifyBD(1, ref tf);
            //debug_log "::AFTER::MODIFYBD::" + tf.ToString();
            ModifyAT(1, ref tf);
            //debug_log "::AFTER::MODIFYAT::" + tf.ToString();
            ModifyTB(1, ref tf);
            ModifyEA(1, ref tf);
            ModifyDT(1, ref tf);
            ModifyCE(1, ref tf);
            ModifyBD(1, ref tf);
            ModifyAT(1, ref tf);
            ModifyTB(1, ref tf);
            ModifyEA(1, ref tf);
            ModifyDT(1, ref tf);
            ModifyCE(1, ref tf);
            ModifyBD(1, ref tf);
            ModifyAT(1, ref tf);
            ModifyTB(1, ref tf);
            ModifyEA(1, ref tf);
            //debug_log("BATCH 1 --> TF HAS: " + tf.ToString());


            ModifyDT(2, ref tf);
            //debug_log("BATCH 2 DT --> TF HAS: " + tf.ToString());
            ModifyCE(2, ref tf);
            //debug_log("BATCH 2 CE --> TF HAS: " + tf.ToString());
            ModifyBD(2, ref tf);
            //debug_log("BATCH 2 BD --> TF HAS: " + tf.ToString());
            ModifyAT(2, ref tf);
            //debug_log("BATCH 2 AT --> TF HAS: " + tf.ToString());
            ModifyTB(2, ref tf);
            //debug_log("BATCH 2 TB --> TF HAS: " + tf.ToString());
            ModifyEA(2, ref tf);
            //debug_log("BATCH 2 EA --> TF HAS: " + tf.ToString());
            ModifyDT(2, ref tf);
            //debug_log("BATCH 2 DT --> TF HAS: " + tf.ToString());
            ModifyCE(2, ref tf);
            //debug_log("BATCH 2 CE --> TF HAS: " + tf.ToString());
            ModifyBD(2, ref tf);
            //debug_log("BATCH 2 BD --> TF HAS: " + tf.ToString());
            ModifyAT(2, ref tf);
            //debug_log("BATCH 2 AT --> TF HAS: " + tf.ToString());
            ModifyTB(2, ref tf);
            //debug_log("BATCH 2 TB --> TF HAS: " + tf.ToString());
            ModifyEA(2, ref tf);
            //debug_log("BATCH 2 EA --> TF HAS: " + tf.ToString());
            ModifyDT(2, ref tf);
            //debug_log("BATCH 2 DT --> TF HAS: " + tf.ToString());
            ModifyCE(2, ref tf);
            //debug_log("BATCH 2 CE --> TF HAS: " + tf.ToString());
            ModifyBD(2, ref tf);
            //debug_log("BATCH 2 BD --> TF HAS: " + tf.ToString());
            ModifyAT(2, ref tf);
            //debug_log("BATCH 2 AT --> TF HAS: " + tf.ToString());
            ModifyTB(2, ref tf);
            //debug_log("BATCH 2 TB --> TF HAS: " + tf.ToString());
            ModifyEA(2, ref tf);
            //debug_log("BATCH 2 EA --> TF HAS: " + tf.ToString());
            ModifyDT(2, ref tf);
            //debug_log("BATCH 2 DT --> TF HAS: " + tf.ToString());
            ModifyCE(2, ref tf);
            //debug_log("BATCH 2 CE --> TF HAS: " + tf.ToString());

            ModifyBD(3, ref tf);
            //debug_log("BATCH 3 BD --> TF HAS: " + tf.ToString());
            ModifyAT(3, ref tf);
            //debug_log("BATCH 3 AT --> TF HAS: " + tf.ToString());
            ModifyTB(3, ref tf);
            //debug_log("BATCH 3 TB --> TF HAS: " + tf.ToString());
            ModifyEA(3, ref tf);
            //debug_log("BATCH 3 EA --> TF HAS: " + tf.ToString());
            ModifyDT(3, ref tf);
            //debug_log("BATCH 3 DT --> TF HAS: " + tf.ToString());
            ModifyCE(3, ref tf);
            //debug_log("BATCH 3 CE --> TF HAS: " + tf.ToString());
            ModifyBD(3, ref tf);
            //debug_log("BATCH 3 BD --> TF HAS: " + tf.ToString());
            ModifyAT(3, ref tf);
            //debug_log("BATCH 3 AT --> TF HAS: " + tf.ToString());
            ModifyTB(3, ref tf);
            //debug_log("BATCH 3 TB --> TF HAS: " + tf.ToString());
            ModifyEA(3, ref tf);
            //debug_log("BATCH 3 EA --> TF HAS: " + tf.ToString());
            ModifyDT(3, ref tf);
            //debug_log("BATCH 3 DT --> TF HAS: " + tf.ToString());
            ModifyCE(3, ref tf);
            //debug_log("BATCH 3 CE --> TF HAS: " + tf.ToString());
            ModifyBD(3, ref tf);
            //debug_log("BATCH 3 BD --> TF HAS: " + tf.ToString());
            ModifyAT(3, ref tf);
            //debug_log("BATCH 3 AT --> TF HAS: " + tf.ToString());
            ModifyTB(3, ref tf);
            //debug_log("BATCH 3 TB --> TF HAS: " + tf.ToString());
            ModifyEA(3, ref tf);
            //debug_log("BATCH 3 EA --> TF HAS: " + tf.ToString());
            ModifyDT(3, ref tf);
            //debug_log("BATCH 3 DT --> TF HAS: " + tf.ToString());
            ModifyCE(3, ref tf);
            //debug_log("BATCH 3 CE --> TF HAS: " + tf.ToString());
            ModifyBD(3, ref tf);
            //debug_log("BATCH 3 BD --> TF HAS: " + tf.ToString());
            ModifyAT(3, ref tf);
            //debug_log("BATCH 3 AT --> TF HAS: " + tf.ToString());

            ModifyTB(4, ref tf);
            ModifyEA(4, ref tf);
            ModifyDT(4, ref tf);
            ModifyCE(4, ref tf);
            ModifyBD(4, ref tf);
            ModifyAT(4, ref tf);
            ModifyTB(4, ref tf);
            ModifyEA(4, ref tf);
            ModifyDT(4, ref tf);
            ModifyCE(4, ref tf);
            ModifyBD(4, ref tf);
            ModifyAT(4, ref tf);
            ModifyTB(4, ref tf);
            ModifyEA(4, ref tf);
            ModifyDT(4, ref tf);
            ModifyCE(4, ref tf);
            ModifyBD(4, ref tf);
            ModifyAT(4, ref tf);
            ModifyTB(4, ref tf);
            ModifyEA(4, ref tf);

            //HmacSha1.debugBytes(digest, "sha_transform::PRESET");
            //debug_log "--> TF HAS: " + tf.ToString();
            digest[0] = Mask32Bit(digest[0] + tf.E);
            digest[1] = Mask32Bit(digest[1] + tf.T);
            digest[2] = Mask32Bit(digest[2] + tf.A);
            digest[3] = Mask32Bit(digest[3] + tf.B);
            digest[4] = Mask32Bit(digest[4] + tf.C);
            //long v = 0xFFFFFFFF;
            //debug_log("V1: " + v.ToString());

            //v = long.Parse("4294967295"); //0xFFFFFFFF
            //debug_log("V3: " + v.ToString());
            //HmacSha1.debugBytes(CONST,"RAW CONST");
            //HmacSha1.debugBytes(digest, "sha_transform::POSTSET");
        }

        public const ushort LITTLE_INDIAN = 1234;
        public const ushort BYTE_ORDER = LITTLE_INDIAN;
        public const int SHA_BLOCKSIZE = 64;
        public const int SHA_DIGESTSIZE = 20;

        //#region Replaces the SHA_INFO structure

        private long[] digest;
        /* message digest */
        private long count_lo, count_hi;
        /* 64-bit bit count */
        private byte[] data;
        /* SHA data buffer */
        private int local;
        /* unprocessed amount in data */

        //#endregion


        //#region SHA constants
/*
        static uint[] CONST = new uint[4]
        {
            0x5a827999, //1518500249
            0x6ed9eba1, //1859775393
            0x8f1bbcdc, //2400959708
            0xca62c1d6  //3395469782
        };
        */
        static long[] CONST;

        //#endregion

        private static ulong maskInt;
        private static long maskFirstByte;
        private static long maskSecondByte;
        private static long maskThirdByte;
        private static long maskFourthByte;
        public Sha1()
        {

        }

        static Sha1()
        {
            maskInt = ulong.Parse("4294967295"); //0xFFFFFFFF);Action
            maskFirstByte = long.Parse("255");  //0xFF
            maskSecondByte = long.Parse("65280"); //0xFF00
            maskThirdByte = long.Parse("16711680"); //0xFF0000
            maskFourthByte = long.Parse("4278190080"); //0xFF000000


            CONST = new long[4];
            CONST[0] = long.Parse("1518500249");
            CONST[1] = long.Parse("1859775393");
            CONST[2] = long.Parse("2400959708");
            CONST[3] = long.Parse("3395469782");

        //#endregion
    }

        /// <summary>
        /// Initialize the SHA digest
        /// </summary>
        public void Init()
        {
            data = new byte[SHA_BLOCKSIZE];
            digest = new long[5];

            digest[0] = long.Parse("1732584193"); //1732584193L;
            digest[1] = long.Parse("4023233417"); //4023233417L;
            digest[2] = long.Parse("2562383102"); //2562383102L;
            digest[3] = long.Parse("271733878"); //271733878L;
            digest[4] = long.Parse("3285377520"); //3285377520L;
            //LOG: ::INIT::DIGEST::1732584193:-271733879:-1732584194:271733878:-1009589776:
            //HmacSha1.debugBytes(digest, "::INIT::DIGEST");
            count_lo = 0L;
            count_hi = 0L;
            local = 0;
        }

        /// <summary>
        /// Update the SHA digest
        /// </summary>
        /// <param name="buffer">Data to be processed</param>
        public void Update(byte[]buffer)
        {
            int i;
            long clo;
            int count = buffer.Length;
            int buf_idx = 0;

            clo = Mask32Bit(count_lo + ((long)count << 3));
            if (clo < count_lo)
            {
                ++count_hi;
            }
            count_lo = clo;
            count_hi += (long)SHA512.shr(count,29); // (long)count >> 29;
            if (local != 0)
            {
                i = SHA_BLOCKSIZE - local;
                if (i > count)
                {
                    i = count;
                }

                //mem._cpy(ref data, local, buffer, buf_idx, i);
                for (int nI = 0; nI < i; nI++)
                {
                    data[local + nI] = buffer[nI + buf_idx];
                }
                count -= i;
                buf_idx += i;

                local += i;
                if (local == SHA_BLOCKSIZE)
                {
                    sha_transform();
                }
                else
                {
                    return;
                }
            }
            while (count >= SHA_BLOCKSIZE)
            {
                //mem._cpy(ref data, 0, buffer, buf_idx, SHA_BLOCKSIZE);
                for (int nI = 0; nI < SHA_BLOCKSIZE; nI++)
                {
                    data[nI] = buffer[nI + buf_idx];
                }
                buf_idx += SHA_BLOCKSIZE;
                count -= SHA_BLOCKSIZE;
                sha_transform();
            }

            //mem._cpy(ref data, 0, buffer, buf_idx, count);
            for (int nI = 0; nI < count; nI++)
            {
                data[nI] = buffer[nI + buf_idx];
            }
            local = count;
        }

        /// <summary>
        /// Finish computing the SHA digest
        /// </summary>
        /// <param name="result"></param>
        public byte[] Final()
        {
            byte[] result = new byte[SHA_DIGESTSIZE];

            int count;
            long lo_bit_count, hi_bit_count;

            lo_bit_count = count_lo;
            hi_bit_count = count_hi;
            //count = (int)((lo_bit_count >> 3) & 0x3f);
            count = (int)((long)SHA512.shr((ulong)lo_bit_count , 3) & 0x3f);
            data[count++] = 0x80;
            if (count > SHA_BLOCKSIZE - 8)
            {
                //mem._set(ref data, count, 0, SHA_BLOCKSIZE - count);
                for (int nI = 0; nI < SHA_BLOCKSIZE - count; nI++)
                {
                    data[nI + count] = 0;
                }
                sha_transform();
                //mem._set(ref data, 0, 0, SHA_BLOCKSIZE - 8);
                for (int nI = 0; nI < SHA_BLOCKSIZE - 8; nI++)
                {
                    data[nI ] = 0;
                }
            }
            else
            {
                //mem._set(ref data, count, 0, SHA_BLOCKSIZE - 8 - count);
                for (int nI = 0; nI < SHA_BLOCKSIZE - 8 - count; nI++)
                {
                    data[nI + count] = 0;
                }
            }


            data[56] = (byte)((hi_bit_count >> 24) & 0xff);
            data[57] = (byte)((hi_bit_count >> 16) & 0xff);
            data[58] = (byte)((hi_bit_count >> 8) & 0xff);
            data[59] = (byte)((hi_bit_count >> 0) & 0xff);
            data[60] = (byte)((lo_bit_count >> 24) & 0xff);
            data[61] = (byte)((lo_bit_count >> 16) & 0xff);
            data[62] = (byte)((lo_bit_count >> 8) & 0xff);
            data[63] = (byte)((lo_bit_count >> 0) & 0xff);
//HmacSha1.debugBytes(digest, "BEFORE FINAL::MEM::TRANSFORM::DIGEST");

sha_transform();
//HmacSha1.debugBytes(digest, "After FINAL::MEM::TRANSFORM::DIGEST");
result[0] = (byte)((digest[0] >> 24) & 0xff);
result[1] = (byte)((digest[0] >> 16) & 0xff);
result[2] = (byte)((digest[0] >> 8) & 0xff);
result[3] = (byte)((digest[0]) & 0xff);
result[4] = (byte)((digest[1] >> 24) & 0xff);
result[5] = (byte)((digest[1] >> 16) & 0xff);
result[6] = (byte)((digest[1] >> 8) & 0xff);
result[7] = (byte)((digest[1]) & 0xff);
result[8] = (byte)((digest[2] >> 24) & 0xff);
result[9] = (byte)((digest[2] >> 16) & 0xff);
result[10] = (byte)((digest[2] >> 8) & 0xff);
result[11] = (byte)((digest[2]) & 0xff);
result[12] = (byte)((digest[3] >> 24) & 0xff);
result[13] = (byte)((digest[3] >> 16) & 0xff);
result[14] = (byte)((digest[3] >> 8) & 0xff);
result[15] = (byte)((digest[3]) & 0xff);
result[16] = (byte)((digest[4] >> 24) & 0xff);
result[17] = (byte)((digest[4] >> 16) & 0xff);
result[18] = (byte)((digest[4] >> 8) & 0xff);
result[19] = (byte)((digest[4]) & 0xff);
//HmacSha1.debugBytes(result, "After FINAL::RESULT");

return result;
}

public byte[] Final_dss_padding()
{
    byte[] result = new byte[SHA_DIGESTSIZE];

    int count;
    long lo_bit_count;
            //long hi_bit_count;

            lo_bit_count = count_lo;
            //hi_bit_count = count_hi;
            count = (int)((lo_bit_count >> 3) & 0x3f);
            if (count > SHA_BLOCKSIZE)
            {
                //mem._set(ref data, count, 0, SHA_BLOCKSIZE - count);
                for (int nI = 0; nI < SHA_BLOCKSIZE-count; nI++)
                {
                    data[nI + count] = 0;
                }
                sha_transform();
                //mem._set(ref data, 0, 0, SHA_BLOCKSIZE);
                for (int nI = 0; nI < SHA_BLOCKSIZE; nI++)
                {
                    data[nI] = 0;
                }
            }
            else
            {
                //mem._set(ref data, count, 0, SHA_BLOCKSIZE - count);
                for (int nI = 0; nI < SHA_BLOCKSIZE -count; nI++)
                {
                    data[nI + count] = 0;
                }
            }

            sha_transform();
            result[0] = (byte)((digest[0] >> 24) & 0xff);
            result[1] = (byte)((digest[0] >> 16) & 0xff);
            result[2] = (byte)((digest[0] >> 8) & 0xff);
            result[3] = (byte)((digest[0]) & 0xff);
            result[4] = (byte)((digest[1] >> 24) & 0xff);
            result[5] = (byte)((digest[1] >> 16) & 0xff);
            result[6] = (byte)((digest[1] >> 8) & 0xff);
            result[7] = (byte)((digest[1]) & 0xff);
            result[8] = (byte)((digest[2] >> 24) & 0xff);
            result[9] = (byte)((digest[2] >> 16) & 0xff);
            result[10] = (byte)((digest[2] >> 8) & 0xff);
            result[11] = (byte)((digest[2]) & 0xff);
            result[12] = (byte)((digest[3] >> 24) & 0xff);
            result[13] = (byte)((digest[3] >> 16) & 0xff);
            result[14] = (byte)((digest[3] >> 8) & 0xff);
            result[15] = (byte)((digest[3]) & 0xff);
            result[16] = (byte)((digest[4] >> 24) & 0xff);
            result[17] = (byte)((digest[4] >> 16) & 0xff);
            result[18] = (byte)((digest[4] >> 8) & 0xff);
            result[19] = (byte)((digest[4]) & 0xff);

            return result;
        }

        // Returns the version
        public static string    version()
        {
            return "SHA-1";
        }

        public static byte[] GetSha1(byte[] key)
        {
            Sha1 sha = new Sha1();
            sha.Init();
            sha.Update(key);
            return sha.Final();
        }

        public static string GetSha1(string key)
        {
            debug_log("GetSha1::" + key);
            byte[] bKey = Utf8.GetBytes(key);
            byte[] result = GetSha1(bKey);
            return BitConverter.ToHex(result);
        }
    }

    // This class provides the HMAC SHA1 algorithm
    public class HmacSha1
    {
        private const int HMAC_SHA1_PAD_SIZE = 64;
        private const int HMAC_SHA1_DIGEST_SIZE = 20;
        private const int HMAC_SHA1_128_DIGEST_SIZE = 16;

        private Sha1 sha_ctx;
        private byte[] key_ctx;
        private int key_len_ctx;
        private byte[] temp_key_ctx = new byte[Sha1.SHA_DIGESTSIZE];
        /* in case key exceeds 64 bytes  */

        public static byte[] GetHmacSha1Bytes(byte[] key, byte[] text)
        {

            HmacSha1 sha = new HmacSha1(key, text);
            return sha.Final();
        }

        private HmacSha1(byte[] key, byte[] text)
        {
            byte[] k_ipad = new byte[HMAC_SHA1_PAD_SIZE];
            int i, key_len = key.Length;

            sha_ctx = new Sha1();

            /* if key is longer than 64 bytes reset it to key=SHA-1(key) */
            if (key_len > HMAC_SHA1_PAD_SIZE)
            {
                sha_ctx.Init();
                sha_ctx.Update(key);
                temp_key_ctx = sha_ctx.Final();

                key = temp_key_ctx;
                key_len = HMAC_SHA1_DIGEST_SIZE;
            }

                /*
               * the HMAC_SHA1 transform looks like:
               *
               * SHA1(K XOR opad, SHA1(K XOR ipad, text))
               *
               * where K is an n byte keyUpdate
               * ipad is the byte 0x36 repeated 64 times
               * opad is the byte 0x5c repeated 64 times
               * and text is the data being protected
               */

            /* start out by storing key in pads */
            mem._set(ref k_ipad, 0, 0, k_ipad.Length);
            mem._cpy(ref k_ipad, 0, key, 0, key_len);

            byte xorKeyInit = (byte) 0x36;
            //* XOR key with ipad and opad values */
            /*
            for (i = 0; i < k_ipad.Length; i++)
            {
                k_ipad[i] ^= xorKeyInit;
            }
            */
            for (i = 0; i < k_ipad.Length; i++)
            {
                k_ipad[i] = (byte)(k_ipad[i] ^ xorKeyInit);
            }

            /*
                * perform inner SHA1
                */
                sha_ctx.Init();
            /* init context for 1st pass */
            /* start with inner pad      */
            sha_ctx.Update(k_ipad);

            /* Stash the key and it's length into the context. */
            key_ctx = key;
            key_len_ctx = key_len;

            sha_ctx.Update(text);
        }

        private byte[] Final()
        {
            byte[] digest;

            /* outer padding -  key XORd with opad */
            byte[] k_opad = new byte[HMAC_SHA1_PAD_SIZE];
            int i;
            byte xorKeyInit = (byte)0x5c;

            mem._set(ref k_opad, 0, 0, k_opad.Length);
            mem._cpy(ref k_opad, 0, key_ctx, 0, key_len_ctx);

            /* XOR key with ipad and opad values */
            /*
            for (i = 0; i < k_opad.Length; i++)
            {
                k_opad[i] ^= xorKeyInit;
            }
              */
              for (i = 0; i < k_opad.Length; i++)
              {
                k_opad[i] =(byte) (k_opad[i] ^ xorKeyInit);
            }

            digest = sha_ctx.Final();         /* finish up 1st pass */
   //debugBytes(digest, "After DIGEST");
            /*
               * perform outer SHA1
               */
            sha_ctx.Init();                  /* init context for 2nd pass */
            /* start with outer pad      */
            sha_ctx.Update(k_opad);

            /* then results of 1st hash  */
            sha_ctx.Update(digest);
            digest = sha_ctx.Final();         /* finish up 2nd pass        */
            debugBytes(digest, "After FINAL DIGEST");
            return digest;
        }

        public static void debugBytes<T>(T[] toPrint, string msg)
        {

            StringBuilder sb = new StringBuilder();
            foreach(T b in toPrint)
            {
                sb.Append(b.ToString());
                sb.Append(":");
            }

            debug_log msg + "::" + sb.ToString();
            
        }
    }


    public class OneTimePassword
    {
        public const int SECRETLENGTH = 20;
        private const string MSG_SECRETLENGTH = "Secret must be at least 20 bytes";
        private const string MSG_COUNTER_MINVALUE = "Counter min value is 1";

        private static int[] _checksumSkipTable = new int[] { 0, 2, 4, 6, 8, 1, 3, 5, 7, 9 };
        private byte[] _secretKey;
        private ulong _counter = 0x0000000000000001;


        public OneTimePassword()
        {
            _secretKey = getDefaultSecretKey();
        }

        public OneTimePassword(ulong counter = 1, string secret = null)
        {

            if (secret != null)
            {
                debug_log("Secret key is not null");
                debug_log(secret);
                byte[] secretKey = Uno.Text.Utf8.GetBytes(secret);
                debug_log(secretKey.Length);
                if (secretKey.Length < SECRETLENGTH)
                {
                    throw new Exception(MSG_SECRETLENGTH);
                }

                this._secretKey = secretKey;
            }
            else
            {
                debug_log("Secret key is null!");
                this._secretKey = getDefaultSecretKey();
            }

            if (counter < 1)
            {
                throw new Exception(MSG_COUNTER_MINVALUE);
            }

            this._counter = counter;
        }

        public OneTimePassword(ulong counter = 1, byte[] secretKey = null)
        {
            if (secretKey != null)
            {
                if (secretKey.Length < SECRETLENGTH)
                {
                    throw new Exception(MSG_SECRETLENGTH);
                }

                this._secretKey = secretKey;
            }
            else
            this._secretKey = getDefaultSecretKey();

            if (counter < 1)
            {
                throw new Exception(MSG_COUNTER_MINVALUE);
            }

            this._counter = counter;
        }

        byte[] getDefaultSecretKey()
        {
            return new byte[]
            {
                0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,
                0x3A,0x3B,0x3C,0x3D,0x3E,0x3F,0x40,0x41,0x42,0x43
            };
        }

        private static int getChecksum(int codeDigits)
        {
            int digitMillions = (codeDigits / 1000000) % 10;
            int digitHundredThousands = (codeDigits / 100000) % 10;
            int digitTenThousands = (codeDigits / 10000) % 10;
            int digitThousands = (codeDigits / 1000) % 10;
            int digitHundreds = (codeDigits / 100) % 10;
            int digitTens = (codeDigits / 10) % 10;
            int digitOnes = codeDigits % 10;
            return (10 -
                ((_checksumSkipTable[digitMillions] + digitHundredThousands +
                    _checksumSkipTable[digitTenThousands] + digitThousands +
                    _checksumSkipTable[digitHundreds] + digitTens +
                    _checksumSkipTable[digitOnes]) % 10)) % 10;
        }

        // Formats the OneTimePassword. This is the OneTimePassword algorithm.
        private static string FormatOneTimePassword(byte[] hmac)
        {

            StringBuilder sb = new StringBuilder();
            foreach(byte b in hmac)
            {
                sb.Append(b.ToString());
                sb.Append(":");
            }

            //debug_log "HMAC::" + sb.ToString();
            int offset = hmac[19] & 0xf;
            int bin_code = (hmac[offset] & 0x7f) << 24
            | (hmac[offset + 1] & 0xff) << 16
            | (hmac[offset + 2] & 0xff) << 8
            | (hmac[offset + 3] & 0xff);

            int Code_Digits = bin_code % 10000000;
            int csum = getChecksum(Code_Digits);
            int OTP = Code_Digits * 10 + csum;
            //debug_log "FOTP::" + hmac[19] + "::" + offset + "::" + bin_code + "::" + Code_Digits + "::" + csum + "::" + OTP + "::" + hmac.Length;

            return string.Format("{0:d08}", OTP);
        }

        public static byte[] ToByteArray(string otp)
        {
            byte[] baOTP = new byte[otp.Length];
            char[] arOTP = otp.ToCharArray();

            for (int nI = 0; nI < otp.Length; nI++)
            {
                baOTP[nI] = (byte)arOTP[nI];
            }

            return baOTP;
        }

        public byte[] CounterArray
        {
            get
            {
                return BitConverter.GetBytes(_counter);
            }

            set
            {
                _counter = BitConverter.ToUInt64(value, 0);
            }
        }

        // Set the OTP secret
        public byte[] Secret
        {
            set
            {
                if (value.Length < SECRETLENGTH)
                {
                    throw new Exception(MSG_SECRETLENGTH);
                }

                _secretKey = value;
            }
        }

        // Get the current one time password value
        public string GetCurrent()
        {
            return FormatOneTimePassword(HmacSha1.GetHmacSha1Bytes(_secretKey, CounterArray));
        }

        // Get the next OTP value
        public string GetNextOneTimePassword()
        {
            // increment the counter
            ++_counter;

            return GetCurrent();
        }

        // Get the counter value
        public ulong Counter
        {
            get
            {
                return _counter;
            }

            set
            {
                _counter = value;
            }
        }
    }


    public class BitConverter
    {

        public static string ToHex(byte[] bytes)
        {

            StringBuilder sbResult = new StringBuilder();

            for (int i=0; i<bytes.Length; i++)
            {
                sbResult.Append(String.Format("{0:x2}", bytes[i]));
            }
            return sbResult.ToString().ToUpper();
        }


        public static void Clear(byte[] arr, int index, int length)
        {
            for(int i = index; i < index+length; i++)
            {
                arr[i] = 0;
            }
        }


        public static byte[] GetBytes(ulong val)
        {
            using (MemoryStream ms = new MemoryStream())
            {
                using (BinaryWriter bw = new BinaryWriter(ms))
                {
                    bw.Write(val);
                    byte[] buff= ms.GetBuffer();
                    byte[] longSizedBuff = new byte[8];
                    Array.Copy(buff,0,longSizedBuff,0,8);
                    return longSizedBuff;
                }
            }
            return null;
        }

        public static ulong ToUInt64(byte[] bytes, int startingIndex)
        {
            using (MemoryStream ms = new MemoryStream())
            {
                ms.Write(bytes,startingIndex, bytes.Length);
                using (BinaryReader br = new BinaryReader(ms))
                {
                    return br.ReadULong();
                }
            }
            return 0;
        }
    }

    public class Tester {

        /* naive shr that doesn't work due to bug in Uno. */
        public static ulong shr(ulong n, uint shiftwidth)
        {
            //return n >> shiftwidth;
            // triggers the bug
            for (uint i=0; i<shiftwidth; i++)
            {
                n = n / 2;
            }
            return n;
        }

        /*
        public static byte[] getBytes(ulong n)
        {
            byte[] bits = new byte[64];
            // clear array
            for (int i=0; i<64; i++) { bits[i] = 0; };
            // set bits
            for (int i=0; i<64; i++) {
              byte byteval = ((n & (1ul<<i)) > 0) ? (byte)1 : (byte)0;
              bits[63-i] = byteval;
            };

            int baseLine = 0;
            byte[] result = new byte[8];
            for(int iByte =0; iByte < 8; iByte++)
            {   
                byte curValue = 0;
                baseLine = 8*iByte;

                for(int offset = 0; offset < 8; offset++)
                {
                    byte bit = bits[baseLine + offset];
                    curValue = (byte)(curValue<<1) + bit;
                }
                result[iByte] = curValue;
            }
            return result;
        }
        */

        public static ulong shr2(ulong n, int shiftwidth)
        {
            ulong result = 0;
            int[] bytes = new int[64];

            // clear array
            for (int i=0; i<64; i++)
            {
                bytes[i] = 0;
            }

            // set bytes
            for (int i=0; i<64; i++)
            {
              int byteval = ((n & (1ul<<i)) > 0) ? 1 : 0;
              bytes[63-i] = byteval;
            }

            // shift right n places
            for (int i=63; i>=0; i--)
            {
              if (i-shiftwidth >= 0)
              {
                bytes[i] = bytes[i-shiftwidth];
              }
              else
              {
                bytes[i] = 0;
              }
            }

            // reconstruct new ulong
            for (int i=0; i<64; i++)
            {
              result = result * 2 + bytes[i];
            }
            return result;
        }

        public static void test_shr(ulong n)
        {
            debug_log n.ToString() + "====>" + shr2(n,6).ToString();
        }

        public static void testAll()
        {
            test_shr(0);
            test_shr(120);
            test_shr(3391362420264868341);
            test_shr(8247344706571482433);
            test_shr(11170817084526286401);

            /* these are the results we get:
            n====>result
            0====>0
            120====>1
            3391362420264868341====>52990037816638567
            8247344706571482433====>128864761040179413
            11170817084526286401====> 18333057714503563097
            // this last one is incorrect... should be: 174544016945723225
            */

        }
    }
}
