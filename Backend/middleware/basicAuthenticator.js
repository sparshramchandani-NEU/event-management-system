
import _ from 'lodash';
import db from "../dbSetup.js";
import bcrypt from "bcryptjs";
export default async (req,res,next)=>{
    
    const authHeader= req.headers.authorization;
    // console.log(authHeader);
    
    if(_.isEmpty(authHeader)){
        //Authentication header is missing
        res.setHeader('WWW-Authenticate', 'Basic');
        return res.status(403).json({error:"You are not authorized user"});
    }   
    const [username,password]= new Buffer.from(authHeader.split(' ')[1],
    'base64').toString().split(':');


    if(!_.isEmpty(username) && !_.isEmpty(password)){
        try{
            let authUser=await db.users.findOne({ where:{
                email:username,
            }});
            if(_.isEmpty(authUser)){
                res.setHeader('WWW-Authenticate', 'Basic');
                return res.status(404).json({error:"No User found with this email address"});
            }
             const isMatch= await bcrypt.compare(password,authUser?.password);
            if(!isMatch){
                res.setHeader('WWW-Authenticate', 'Basic');
                return res.status(401).json({error:"You are not authorized user"});
            }
            req.authUser=authUser.dataValues;
            console.log(req.authUser,"<-- this is auth user");
            delete req.authUser?.password;
        }catch(err){
            console.log(err);
            return res.status(401).json({error:"You are not authorized user"});
        }      
    }else{
         //Authentication header is missing
         res.setHeader('WWW-Authenticate', 'Basic');
         return res.status(403).json({error:"You are not authorized user"});
    }
    next();
}